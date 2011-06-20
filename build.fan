using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "peg"
    summary = ""
    srcDirs = [`fan/`, `fan/example/`]
    depends = ["sys 1.0"]
  }
}
