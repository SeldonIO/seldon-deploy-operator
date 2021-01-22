import yaml
import argparse
import sys


def getOpts(cmd_line_args):
    parser = argparse.ArgumentParser(
        description="remove csv CRD versions and update version"
    )
    parser.add_argument("--path", help="the output path to save result")
    parser.add_argument("--version", help="the release version")
    parser.add_argument("--replaces", help="the bundle it replaces")
    opts = parser.parse_args(cmd_line_args)
    return opts


def update_container_image(csv, version):
    csv["metadata"]["annotations"]["containerImage"] = "quay.io/seldon/seldon-deploy-server-operator:"+version
    csv["metadata"]["name"] = "seldon-deploy-operator.v"+version
    deployments = csv["spec"]["install"]["spec"]["deployments"]
    for deployment in deployments:
        if deployment["name"] == "seldon-deploy-operator-controller-manager":
            containers = deployment["spec"]["template"]["spec"]["containers"]
            for c in containers:
                if c["name"] == "manager":
                    c["image"] = "quay.io/seldon/seldon-deploy-server-operator:"+version
    return csv

def update_replaces(csv, replaces):
    csv["spec"]["replaces"] = "seldon-deploy-operator.v"+replaces
    return csv

def str_presenter(dumper, data):
    if len(data.splitlines()) > 1:  # check for multiline string
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)


def main(argv):
    opts = getOpts(argv[1:])
    print(opts)
    with open(opts.path, "r") as stream:
        csv = yaml.safe_load(stream)
        csv = update_container_image(csv, opts.version)
        csv = update_replaces(csv, opts.replaces)
        fdata = yaml.dump(csv, width=1000, default_flow_style=False, sort_keys=False)
        with open(opts.path, "w") as outfile:
            outfile.write(fdata)


if __name__ == "__main__":
    yaml.add_representer(str, str_presenter)
    main(sys.argv)