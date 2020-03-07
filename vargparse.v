module vargparse

import os

struct OptArg {
    store bool
mut:
    flg bool
    arg string
}

struct ArgParser {
mut:
    positional map[string]int
    p_arg []string
    p_arg_ext []string
    optional map[string]OptArg
    o_arg map[string]string
    argc int
    argv []string

}

enum OptType {
    name
    short
    long
}

pub fn parser() ArgParser{
    return ArgParser {
        argc: os.args.len
        argv: os.args
    }
}

fn is_optional(opt string) OptType {
    mut ret := OptType.name

    if opt.starts_with("-") {
        ret = if opt[1].str() == "-" {
            OptType.long
        } else {
            OptType.short
        }
    }
    return ret
}

pub fn (p mut ArgParser) add_argument(option ...string) {
    opt := option[0]
    match is_optional(opt) {
        .name {
            p.positional[opt] = p.positional.keys().len
        }
        .short {
            oa := OptArg{store :opt.ends_with(":")}
            o := opt.trim(":")
            p.optional[o] = oa

        }
        .long {
            oa := OptArg{store :opt.ends_with(":")}
            o := opt.trim(":")
            p.optional[o] = oa
        }
        else {
            p.positional[opt] = p.positional.keys().len
        }
    }
}

fn (p ArgParser) get_opt(option string) string {
    mut ret := ""
    if !(option in p.optional) {
        return ret
    }

    ret = if p.optional[option].store {
        p.optional[option].arg
    } else {
        p.optional[option].flg.str()
    }
    return ret
}

fn (p ArgParser) get_pos(option string) string {
    mut ret := ""

    if option in p.positional {
        idx := p.positional[option]
        len := p.p_arg.len
        if len > idx {
            ret = p.p_arg[idx]
        }
    }
    return ret
}

pub fn (p ArgParser) get(option string) string{
    return match is_optional(option) {
        .name { p.get_pos(option) }
        .short { p.get_opt(option) }
        .long { p.get_opt(option) }
        else {""}
    }
}

pub fn (p ArgParser) get_etc() []string {
    mut etc := []string
    p_len := p.positional.keys().len
    if p_len < p.p_arg.len {
        etc = p.p_arg[p_len..]
    }
    return etc
}

fn (p mut ArgParser) add_posarg(arg string) {
    mut o := p.p_arg
    o << arg
    p.p_arg = o
}

fn (p mut ArgParser) add_optarg(opt, arg string) bool{
    mut l := p.optional[opt]

    return if l.store {
        l.arg = arg
        p.optional[opt] = l
        true
    } else {
        l.flg = true
        p.optional[opt] = l
        false
    }
}

pub fn (p mut ArgParser) parse() {
    for i := 1; i < p.argc; i++ {
        match is_optional(p.argv[i]) {
            .name {
                match is_optional(p.argv[i-1]) {
                    .name {
                        p.add_posarg(p.argv[i])
                    }
                    .short {}
                    .long {}
                    else {}
                }
            }
            .short {
                if p.add_optarg(p.argv[i], p.argv[i+1]) {
                    i++
                }
            }
            .long {
                if p.add_optarg(p.argv[i], p.argv[i+1]) {
                    i++
                }
            }
            else {}
        }
    }
}

