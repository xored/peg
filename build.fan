using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "peg"
    summary = ""
    srcDirs = [`fan/`]
    depends = ["sys 1.0"]
  }
}
