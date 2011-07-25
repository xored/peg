using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "peg"
    summary = ""
    srcDirs = [`test/`, `fan/`, `fan/examples/`]
    depends = ["sys 1.0"]
  }
}
