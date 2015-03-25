using build

class Build : build::BuildPod
{
  new make()
  {    
    podName = "peg"
    version = Version.fromStr((scriptDir + `version`).readAllLines.first)
    summary = "PEG parser"
    meta = ["vcs.uri" : "https://github.com/xored/peg", "license.name":"Eclipse Public License"]
    srcDirs = [`test/`, `fan/`]
    resDirs = [`res/`]
    depends = ["sys 1.0"]
  }
}
