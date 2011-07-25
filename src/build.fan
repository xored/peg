using build

class Build : build::BuildPod
{
  new make()
  {    
    podName = "peg"
    version = Version.fromStr("0.8")
    summary = ""
    srcDirs = [`test/`, `fan/`, `fan/examples/`]
    depends = ["sys 1.0"]
  }
}
