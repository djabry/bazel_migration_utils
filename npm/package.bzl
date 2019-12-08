# Based on https://github.com/dataform-co/dataform/blob/master/tools/npm/package.bzl

load("@build_bazel_rules_nodejs//:defs.bzl", "npm_package")

def enhanced_npm_package(name, deps, module_name, root_package_json, version, srcs = [], package_layers = [], npm_deps = []):

    # Generate the "dependencies" section of the output package.json
    package_deps_name = name + "_package_deps"

    npm_deps_string = " ".join(npm_deps)
    native.genrule(
        name = package_deps_name,
        tools = ["//deps-builder:bin", root_package_json],
        srcs = npm_deps,
        outs = ["package-deps.json"],
        cmd = "$(location //deps-builder:bin) --output-path $(OUTS) --npm-deps {npm_deps} --package-json-path $(location {root_package_json})".format(npm_deps = npm_deps_string, root_package_json = root_package_json),
    )

    package_json_name = name + "_gen_package_json"
    native.genrule(
        name = package_json_name,
        srcs = [":" + package_deps_name] + package_layers,
        tools = ["//json-merger:bin"],
        outs = ["package.json"],
        cmd = "$(location //json-merger:bin) --output-path $(OUTS) --layer-paths $(SRCS) --substitutions '{{ \"$$VERSION\": \"{version}\", \"$$MODULE_NAME\": \"{module_name}\" }}'".format(version = version, module_name = module_name)
    )

    npm_package(
        name = name,
        srcs = srcs,
        deps = deps + [package_json_name],
    )

    native.genrule(
        name = name + "_tar",
        srcs = [":" + name],
        outs = [name + ".tgz"],
        cmd = "tar -cvzf $(location {name}.tgz) -C $(location :{name})/.. --dereference {name}"
            .format(name = name),
    )
