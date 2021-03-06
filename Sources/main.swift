//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//    Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectSessionMySQL

// An example request handler.
// This 'handler' function can be referenced directly in the configuration below.
func allhandler(data: [String:Any]) throws -> RequestHandler {
    return {
        request, response in
        // Respond with a simple message.
        response.setHeader(.contentType, value: "text/html")
        response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
        // Ensure that response.completed() is called when your processing is done.
        
//        print(fetchDataByProcedure(name: "proc_moive_get_by_id", args: ["1"], columns: ["title", "id", "page", "images_url", "download_urls_id"]) ?? "error")
//        print(fetchDataBySQL(statement: "SELECT a.title, a.id, a.page, a.images_id, a.download_urls_id FROM table_movie a WHERE a.id = 1;", columns: ["title", "id", "page", "images_url", "download_urls_id"]) ?? "error")
//        print(request.params())
        response.completed()
    }
}

// Configuration data for an example server.
// This example configuration shows how to launch a server
// using a configuration dictionary.

let confData = [
    "servers": [
        // Configuration data for one server which:
        //    * Serves the hello world message at <host>:<port>/
        //    * Serves static files out of the "./webroot"
        //        directory (which must be located in the current working directory).
        //    * Performs content compression on outgoing data when appropriate.
        [
            "name":"localhost",
            "port":8181,
            "routes":[
                ["method":"get", "uri":"/", "handler":allhandler],
                ["method":"get", "uri":"/api", "handler":apiSpaHandler],
                ["method":"post", "uri":"/api", "handler":apiSpaHandler],
                ["method":"get", "uri":"/**", "handler":PerfectHTTPServer.HTTPHandler.staticFiles,
                 "documentRoot":"./webroot",
                 "allowResponseFilters":true]
            ],
            "filters":[
                [
                "type":"response",
                "priority":"high",
                "name":PerfectHTTPServer.HTTPFilter.contentCompression,
                ]
            ]
        ]
    ]
]

do {
    // Launch the servers based on the configuration data.
//    Log.info(message: "MD5: \("123".md5()) SHA256:\("123".sha256())")
    let server = HTTPServer()
    server.serverName = "localhost"
    server.serverPort = 8181
    var routes = Routes()
    routes.add(method: .get, uri: "/api", handler: try apiSpaHandler())
    routes.add(method: .post, uri: "/api", handler: try apiSpaHandler())
    routes.add(method: .get, uri: "/", handler: try allhandler(data: [:]))
    routes.add(method: .get, uri: "/", handler: try PerfectHTTPServer.HTTPHandler.staticFiles(data: [:]))
    server.addRoutes(routes)
    server.documentRoot = "./webroot"
    let sessionDriver = SessionMySQLDriver()
    server.setRequestFilters([sessionDriver.requestFilter])
    server.setResponseFilters([sessionDriver.responseFilter])
    try server.start()
//    try HTTPServer.launch(configurationData: confData)
} catch {
    fatalError("\(error)") // fatal error launching one of the servers
}

