# Duplicate Builds with Configuration Transitions

The target `//:cat` is independent of the user defined build flag `//:flag`.
The target `//:flag_cat` on the other hand depends on the value of the flag and
on `//:cat` as well.

The target `//:cat` is only built once, and cached under the same action cache
key, if the configuration is set via command-line flag.

```
$ bazel clean --expunge; bazel build //:flag_cat --disk_cache=.cache/default --build_event_publish_all_actions --build_event_json_file=default.json

$ bazel clean --expunge; bazel build //:flag_cat --//:flag=different_flag --disk_cache=.cache/different --build_event_publish_all_actions --build_event_json_file=different.json

$ jq 'select(.id.actionCompleted.label == "//:cat")' <default.json | jq -s length
1

$ jq 'select(.id.actionCompleted.label == "//:cat")' <different.json | jq -s length
1

$ rg 'bin/cat.txt' .cache/*/ac
.cache/default/ac/b9/b966d571c54c4aa37fc5ae7629f95caaa01ad79474fdc406c9e9a79341c950f6
2:"bazel-out/k8-fastbuild/bin/cat.txtD

.cache/different/ac/b9/b966d571c54c4aa37fc5ae7629f95caaa01ad79474fdc406c9e9a79341c950f6
2:"bazel-out/k8-fastbuild/bin/cat.txtD
```

The targets `//:transition_default` and `//:transition_different` use a
configuration transition to set the value of the build setting `//:flag` to
`"default_flag"` and `"different_flag"` respectively.

The target `//:cat` is built twice and cached under different action cache keys
when building these transition targets, even though `//:cat` does not depend on
the build setting.

```
$ bazel clean --expunge; bazel build //:transition_default //:transition_different --disk_cache=.cache/transition --build_event_publish_all_actions --build_event_json_file=transition.json

$ jq 'select(.id.actionCompleted.label == "//:cat")' <transition.json | jq -s length
2

$ rg 'bin/cat.txt' .cache/transition/ac
.cache/transition/ac/b9/b966d571c54c4aa37fc5ae7629f95caaa01ad79474fdc406c9e9a79341c950f6
2:"bazel-out/k8-fastbuild/bin/cat.txtD

.cache/transition/ac/8a/8a979615135482bd13afbdf6004d5c87c0a5f3427bcedc299f496eeff4946e29
2:2bazel-out/k8-fastbuild-ST-1d73fa6ab729/bin/cat.txtD
```
