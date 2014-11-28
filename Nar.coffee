JSZip = @JSZip
XMLHttpRequest = @XHRProxy
if this["process"]?
  JSZip ?= require 'jszip'
  XMLHttpRequest ?= require 'uupaa.nodeproxy.js'

class NarLoader

  loadFromBuffer: (buffer, callback)->
    try
      nar = new Nar(NarLoader.unzip(buffer))
    catch err
      return callback(err)
    setTimeout ->
      callback(null, nar)
  loadFromURL: (src, callback)->
    NarLoader.wget src, "arraybuffer", (err, buffer)=>
      if !!err then return callback(err)
      @loadFromBuffer(buffer, callback)

  loadFromBlob: (blob, callback)->
    url = URL.createObjectURL(blob)
    @loadFromURL url, (err, nar)->
      URL.revokeObjectURL(url)
      callback(err, nar)

  @unzip = (buffer)->
    zip = new JSZip()
    zip.load(buffer)
    dic = {}
    for filePath of zip.files
      path = filePath.split("\\").join("/")
      dic[path] = zip.files[filePath]
    dic

  @wget = (url, type, callback)->
    xhr = new XMLHttpRequest()
    xhr.addEventListener "load", ->
      if 200 <= xhr.status && xhr.status < 300
        if !!xhr.response.error
        then callback(new Error(xhr.response.error.message), null)
        else callback(null, xhr.response)
      else callback(new Error(xhr.status), null)
    xhr.open("GET", url)
    xhr.responseType = type
    xhr.send()
    undefined

Encoding = @Encoding
WMDescript = @WMDescript
if this["process"]?
  Encoding ?= require 'encoding-japanese'
  WMDescript ?= require 'ikagaka.wmdescript.js'

class Nar

  constructor: (@directory) ->
    if !@directory["install.txt"]
      throw new Error("install.txt not found")
    @install = Nar.parseDescript(Nar.convert(@directory["install.txt"].asArrayBuffer()))

  grep: (regexp)->
    Object.keys(@directory).filter (path)-> regexp.test(path)

  getDirectory: (regexp)->
    @grep(regexp)
      .reduce(((dir, path, zip)=>
        dir[path.replace(regexp, "")] = @directory[path]
        dir
      ), {})

  @convert = (buffer)->
    Encoding.codeToString(Encoding.convert(new Uint8Array(buffer), 'UNICODE', 'AUTO'))

  @parseDescript = (text)->
    WMDescript.parse(text)

if module?.exports?
  module.exports = Nar: Nar, NarLoader: NarLoader
else if @Ikagaka?
  @Ikagaka.Nar = Nar
  @Ikagaka.NarLoader = NarLoader
else
  @Nar = Nar
  @NarLoader = NarLoader
