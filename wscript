#!/usr/bin/env python

# Setup options for display when running waf --help
def options(ctx):
    ctx.load("flambe")

# Setup configuration when running waf configure
def configure(ctx):
    ctx.load("flambe")

# Runs the build!
def build(ctx):
    if ctx.env.debug: print("This is a debug build!")

    classpaths = []
    
    for p in ["./demo/src"]:
        classpaths.append(ctx.path.find_dir(p))

    # Kick off a build with the desired platforms
    ctx(name="websocket", 
        features="flambe-server",
        npm_libs="commander websocket connect",
        main="demo.devserver.TestWebsocketRouter",
        classpath=classpaths,
        libs="flambe nodejs nodejs_externs nodejs-std",
        target="server.js")
    
    ctx(name="websocket", 
        features="flambe-server",
        npm_libs="commander websocket",
        main="demo.devserver.TestWebsocketRouterClient",
        classpath=classpaths,
        libs="flambe nodejs nodejs_externs nodejs-std",
        target="client.js")
    
    ctx(features="flambe-server",
        name="remoting", 
        npm_libs="connect commander",
        main="demo.devserver.RemotingServer",
        classpath=classpaths,
        libs="flambe nodejs nodejs_externs nodejs-std",
        target="server.js")
    
    ctx(name="remoting", 
        features="flambe-server",
        npm_libs="connect commander",
        main="demo.devserver.RemotingClient",
        classpath=classpaths,
        libs="flambe nodejs nodejs_externs nodejs-std",
        target="client.js")
