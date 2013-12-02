fs         = require 'fs'
optimist   = require 'optimist'
prettyjson = require 'prettyjson'
minimatch  = require 'minimatch'
GitHub     = require '../lib/github'

options = optimist
  .usage("""
    Usage: github-releases [--tag==<tag>] [--filename=<filename>] [--token=<token>] <command> <repo>
  """)
  .alias('h', 'help').describe('help', 'Print this usage message')
  .string('token').describe('token', 'Your GitHub token')
  .string('tag').describe('tag', 'The tag of the release')
  .string('filename').describe('filename', 'The filename of the asset')
                     .default('filename', '*')

print = (error, result) ->
  if error?
    message = error.message ? error
    console.error "Command failed with error: #{message}"
  else
    console.log prettyjson.render(result)

run = (github, command, argv, callback) ->
  switch command
    when 'list'
      github.getReleases print

    when 'show'
      getRelease =
        if argv.tag?
          github.getReleaseOfTag.bind github, argv.tag
        else
          github.getLatestRelease.bind github
      getRelease callback

    when 'download'
      run github, 'show', argv, (error, releases) ->
        return print(error) if error?
        for asset in releases.assets when asset.state is 'uploaded' and minimatch asset.name, argv.filename
          do (asset) ->
            github.downloadAsset asset, (error, stream) ->
              return console.error("Unable to download #{asset.name}") if error?
              stream.pipe fs.createWriteStream(asset.name)

    else
      console.error "Invalid command: #{command}"

argv = options.argv
if argv._.length < 2 or argv.h
  return options.showHelp()

command = argv._[0]
github = new GitHub(repo: argv._[1], token: argv.token)
run github, command, argv, print
