def _cat_impl(ctx):
    ctx.actions.run_shell(
        outputs = [ctx.outputs.out],
        inputs = ctx.files.srcs,
        command = """\
cat >{output} "$@"
echo "{string}" >>{output}
""".format(
            output = ctx.outputs.out.path,
            string = ctx.attr.string,
        ),
        arguments = [f.path for f in ctx.files.srcs],
        mnemonic = "Cat",
        progress_message = "Writing {}".format(ctx.outputs.out.short_path),
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

cat = rule(
    _cat_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "string": attr.string(mandatory = True),
        "out": attr.output(mandatory = True),
    },
)

FlagProvider = provider(fields = ["value"])

def _flag_impl(ctx):
    return FlagProvider(value = ctx.build_setting_value)

flag = rule(
    _flag_impl,
    build_setting = config.string(flag = True),
)

def _flag_cat_impl(ctx):
    ctx.actions.run_shell(
        outputs = [ctx.outputs.out],
        inputs = ctx.files.srcs,
        command = """\
{{
  cat "$@"
  echo "{string}"
}} | sed -e 's/^/{prefix}: /' >{output}
""".format(
            output = ctx.outputs.out.path,
            prefix = ctx.attr._flag[FlagProvider].value,
            string = ctx.attr.string,
        ),
        arguments = [f.path for f in ctx.files.srcs],
        mnemonic = "FlagCat",
        progress_message = "Writing {} with prefix {}".format(
            ctx.outputs.out.short_path,
            ctx.attr._flag[FlagProvider].value,
        ),
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

flag_cat = rule(
    _flag_cat_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "string": attr.string(mandatory = True),
        "out": attr.output(mandatory = True),
        "_flag": attr.label(default = Label("//:flag")),
    },
)

def _flag_transition_impl(settings, attr):
    flag = attr.flag
    return {"//:flag": attr.flag}

flag_transition = transition(
    implementation = _flag_transition_impl,
    inputs = [],
    outputs = ["//:flag"],
)

def _flag_files_impl(ctx):
    files = ctx.files.srcs
    return [DefaultInfo(
        files = depset(direct = files),
    )]

flag_files = rule(
    _flag_files_impl,
    attrs = {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "flag": attr.string(),
        "srcs": attr.label_list(allow_files = True),
    },
    cfg = flag_transition,
)
