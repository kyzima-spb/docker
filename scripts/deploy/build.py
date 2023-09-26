from __future__ import annotations
import argparse
import logging
import importlib
import os
from packaging import version
from pathlib import Path
import platform
from random import randrange
import secrets
from string import digits, ascii_letters
import sys
import subprocess
import typing as t
from urllib.error import HTTPError
from urllib.request import urlopen


__VERSION__ = '0.1.4'
BASE_URL = 'https://kyzima-spb.github.io/docker-useful/scripts/deploy'

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)


class UpdateAction(argparse.Action):
    def __init__(self, *args, **kwargs) -> None:
        kwargs['dest'] = argparse.SUPPRESS
        kwargs['default'] = argparse.SUPPRESS
        kwargs['nargs'] = 0
        super().__init__(*args, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        url = f'{BASE_URL}/build.py'
        current_version = version.parse(__VERSION__)

        try:
            with urlopen(url) as u:
                script = u.read().decode()
                latest_version = version.parse(
                    subprocess.check_output(['python3', '-c', script, '-v'], text=True)
                )

            formatter = parser._get_formatter()

            if current_version < latest_version:
                Path(__file__).write_text(script)
                formatter.add_text('The update was successful')
            else:
                formatter.add_text('The latest version is installed.')

            parser._print_message(formatter.format_help())
            parser.exit()
        except HTTPError as err:
            parser.exit(1, f'{err}\n')


class Context:
    def __call__(self, func):
        self.__dict__[func.__name__] = func
        return func

    def __repr__(self):
        methods = ', '.join(self.__dict__)
        return '<%s (%s)>' % (self.__class__.__name__, methods)


ctx = Context()


def execute_user_scripts(argv, context: Context) -> int:
    """Выполняет пользовательские скрипты из директории build.d."""
    scripts_dir = Path(__file__).with_suffix('.d')

    if not scripts_dir.is_dir():
        return 1

    for filename in sorted(scripts_dir.iterdir()):
        suffix = filename.suffix

        if suffix == '.py':
            name = filename.stem.replace('-', '_')

            spec = importlib.util.spec_from_file_location(name, filename)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)

            if hasattr(module, 'main'):
                module.main(argv, context)
        elif filename.is_file() and os.access(filename, os.X_OK):
            subprocess.check_call(
                str(filename),
                cwd=argv.workdir,
            )

    return 0


@ctx
def backup_file(path: Path) -> None:
    """Переименовывает файл, добавляя расширение .back."""
    if path.exists():
        logger.info('Backup "%s"' % path)
        backup_path = path.with_suffix('%s.back' % path.suffix)
        path.rename(backup_path)


@ctx
def restore_file(path: Path) -> None:
    """Находит файл с расширением .back и удаляет это расширение из имени файла."""
    backup_path = path.with_suffix('%s.back' % path.suffix)
    if backup_path.exists():
        logger.info('Restore "%s"' % path)
        backup_path.rename(path)


@ctx
def init_gitmodules(repo_path: Path) -> None:
    """Инициализирует модули Git, если они есть в проекте."""
    if not (repo_path / '.gitmodules').exists():
        return None

    output = subprocess.check_output(['git', 'submodule', 'status'], text=True, cwd=repo_path)
    uninitialized_modules = [
        (c, d)
        for c, d, *_ in (i.split() for i in output.splitlines())
        if c.startswith('-')
    ]

    for commit, directory in uninitialized_modules:
        subprocess.check_call(['git', 'submodule', 'init', directory], cwd=repo_path)
        subprocess.check_call(['git', 'submodule', 'update', directory], cwd=repo_path)


@ctx
def make_secret(
    secret_file: Path,
    length: t.Optional[int] = None,
    rewrite: bool = False,
    value: t.Callable[[], str] = '',
    symbols: str = digits + ascii_letters + '!#$%&()*+-.;=?[]^_{}~',
) -> None:
    """Создает файл с данными, который будет использоваться как Docker-секрет."""
    if secret_file.exists() and not rewrite:
        logger.info('%s: using an existing secret' % secret_file.name)
        return None

    if length is None or length < 1:
        length = randrange(64, 128)

    if not value:
        value = ''.join(secrets.choice(symbols) for _ in range(length))
    elif callable(value):
        value = value()

    secret_file.parent.mkdir(parents=True, exist_ok=True)
    secret_file.write_text(value)
    logger.info('%s: the secret has been created' % secret_file.name)


def user_input(msg='Введите значение', default=None, value_callback=None,
               trim_spaces=True, show_default=True, required=False):
    if show_default and default is not None:
        msg += f' [{default}]'

    if default is not None:
        required = False

    while 1:
        value = input(f'{msg}: ')

        if trim_spaces:
            value = value.strip()

        if value:
            if value_callback is None:
                return value

            try:
                return value_callback(value)
            except ValueError as err:
                print(err)

        else:
            if not required:
                return default

            print('Требуется ввести значение')


@ctx
def prompt(
    msg: str,
    default: t.Optional[t.Any] = None,
    callback: t.Optional[t.Callable[[str], t.Any]] = None,
    trim_spaces: bool = True,
    show_default: bool = True,
) -> t.Any:
    """
    Requests input from the user and returns input.

    Arguments:
        msg (str): prompt message.
        default (mixed): the value to be used if the input is empty.
        callback (callable): callback function to process the entered value.
        trim_spaces (bool): remove spaces from the beginning and end of a string.
        show_default (bool): show default value when entering.
    """
    if show_default and default is not None:
        msg += f' [{default}]'

    while 1:
        value = input(f'{msg}: ')

        if trim_spaces:
            value = value.strip()

        try:
            if not value and default is None:
                raise ValueError('Value required')

            if not value:
                value = default

            if callback is None:
                return value

            return callback(value)
        except ValueError as e:
            print(e)


def main() -> int:
    parser = argparse.ArgumentParser(
        epilog=f'URL ({BASE_URL})'
    )
    parser.add_argument(
        '-v', '--version',
        action='version',
        version=__VERSION__,
    )
    parser.add_argument(
        '--update',
        action=UpdateAction,
        help='Update the current version of the program.',
    )
    parser.add_argument(
        '-w', '--workdir',
        type=lambda p: Path(p).absolute(),
        default=Path.cwd(),
        help='Project root directory. By default, the current directory.',
    )
    parser.add_argument(
        '--development',
        action='store_true',
        default=bool(int(os.environ.get('DEVELOPMENT', 0))),
    )
    argv = parser.parse_args()

    os.environ.setdefault('PROJECT_DIR', str(argv.workdir))
    os.environ.setdefault('DEVELOPMENT', str(int(argv.development)))

    if not argv.development:
        delimiter = ';' if platform.system() == 'Windows' else ':'
        files = [
            argv.workdir / 'docker-compose.yml',
            argv.workdir / 'docker-compose.prod.yml',
        ]
        os.environ.setdefault(
            'COMPOSE_FILE',
            delimiter.join(str(f) for f in files if f.exists())
        )

    return execute_user_scripts(argv, ctx)


if __name__ == '__main__':
    sys.exit(main())
