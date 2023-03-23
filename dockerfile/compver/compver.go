package main

import (
	"errors"
	"flag"
	"os"
	"regexp"

	"github.com/hashicorp/go-version"
)

func main() {
	var v1 *version.Version
	var v2 *version.Version
	var op string

	flag.Func("v1", "Version as left operand.", func(s string) error {
		v, err := version.NewVersion(s)
		v1 = v
		return err
	})
	flag.Func("v2", "Version as right operand.", func(s string) error {
		v, err := version.NewVersion(s)
		v2 = v
		return err
	})
	flag.Func(
		"op",
		"Comparison operator.\nAvailable values: == != > < >= <=",
		func(s string) error {
			re := regexp.MustCompile("^(==|!=|>|<|>=|<=)$")
			if !re.MatchString(s) {
				return errors.New("available values: == != > < >= <=")
			}
			op = s
			return nil
		},
	)
	flag.Parse()

	if v1 == nil || v2 == nil || op == "" {
		flag.Usage()
		os.Exit(1)
	}

	result := false

	switch op {
	case "==":
		result = v1.Equal(v2)
	case "!=":
		result = !v1.Equal(v2)
	case ">=":
		result = v1.GreaterThanOrEqual(v2)
	case "<=":
		result = v1.LessThanOrEqual(v2)
	case ">":
		result = v1.GreaterThan(v2)
	case "<":
		result = v1.LessThan(v2)
	}

	if result {
		os.Exit(0)
	}

	os.Exit(1)
}
