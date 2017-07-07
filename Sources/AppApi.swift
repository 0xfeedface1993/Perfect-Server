//
//  api.swift
//  PerfectTemplate
//
//  Created by virus1993 on 2017/6/30.
//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

enum ErrorCode : Int {
    case jsonEcoding = 0x1
}

let EmptyArrayString = "[]"

func apiSpaHandler(data: [String:Any]) throws -> RequestHandler {
    return {
        request, response in
        // Respond with a simple message.
        response.setHeader(.contentType, value: "text/html")
        
        if request.params().count > 0, let method = request.param(name: "method")  {
            switch method {
            case "addMovie":
                response.appendBody(string: addMovie(request: request))
                break
            case "getMovieByID"://localhost:8181/api?method=getMovieByID&id=1
                response.appendBody(string: getMovieByID(request: request))
                break
            case "getImages"://localhost:8181/api?method=getImages&id=1
                response.appendBody(string: getImagesByID(request: request))
                break
            case "getLinks"://localhost:8181/api?method=getLinks&id=1
                response.appendBody(string: getLinksByID(request: request))
                break
            case "getMovies"://localhost:8181/api?method=getMovies
                response.appendBody(string: getMovies())
                break
            default:
                response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
                break
            }
        }
        
        response.completed()
    }
}


/// 添加电影信息
///
/// - Parameter request: 包含参数信息（电影、图片、下载地址）
/// - Returns: 添加成功返回电影id， 否则返回空数组或者error信息
func addMovie(request: HTTPRequest) -> String {
    // {"title":"", "page":"", "pics":["", "", ""], "downloads":["", "", ""]}
    if let str = request.postBodyString {
        do {
            guard let json = try str.jsonDecode() as? [String:Any] else {
                return "{\"error\":\"BAD PARAMETER\"}"
            }
            
            if let title = json["title"] as? String,
                let page = json["page"] as? String,
                let pics = json["pics"] as? [String],
                let downloads = json["downloads"] as? [String],
                let results = fetchDataByProcedure(name: "proc_moive_add", args: ["'\(title)'", "'\(page)'"], columns: ["movie_id"]), results.count > 0,
                let first = results[0]["movie_id"] as? String {
                let tasks = downloads.map({
                    item in
                    return Procedure(name: "proc_download_add", args: ["'\(item)'", "'\(first)'"], colmns:  ["id"])
                }) + pics.map({
                    item in
                    return Procedure(name: "proc_image_add", args: ["'\(first)'", "'\(item)'"], colmns:  ["id"])
                })
                
                guard let _ = updateByProcedures(procedures: tasks) else {
                    return "{\"error\":\"BAD SAVE\"}"
                }
                
                return first
            }   else    {
                return EmptyArrayString
            }
            
        }   catch   {
            Log.info(message: "error json decoding: \(error)")
            print("json decode failed!")
        }
    }
    return EmptyArrayString
}

func getMovieByID(request: HTTPRequest) -> String {
    if let args = request.param(name: "id")?.characters.split(separator: "|").map({String($0)}) {
        let movie = fetchDataByProcedure(name: "proc_moive_get_by_id", args: args, columns: ["title", "id", "page"]) ?? []
        do {
            let json = try movie.jsonEncodedString()
            return json
        } catch {
            print("error json edncoding: \(error)")
            Log.info(message: "error json edncoding: \(error)")
            return "server error code: \(ErrorCode.jsonEcoding.rawValue)"
        }
    }
    return EmptyArrayString
}

/// 获取电影列表
///
/// - Returns: json数组
func getMovies() -> String {
    let movie = fetchDataByProcedure(name: "proc_movie_get_all", args: [], columns: ["title", "page", "id", "create_time"]) ?? [] ////a.title, a.page, a.id, a.create_time
    do {
        let json = try movie.jsonEncodedString()
        return json
    } catch {
        print("error json edncoding: \(error)")
        Log.info(message: "error json edncoding: \(error)")
//        return "server error code: \(ErrorCode.jsonEcoding.rawValue)"
        return EmptyArrayString
    }
}


/// 获取电影的图片
///
/// - Parameter request: 包含参数信息
/// - Returns: 图片数据json字符串
func getImagesByID(request: HTTPRequest) -> String {
    if let args = request.param(name: "id") {
        let movie = fetchDataByProcedure(name: "proc_image_get_by_movie_id", args: [args], columns: ["id", "image_url", "create_time"]) ?? []
        do {
            let json = try movie.jsonEncodedString()
            return json
        } catch {
            print("error json edncoding: \(error)")
            Log.info(message: "error json edncoding: \(error)")
            return "server error code: \(ErrorCode.jsonEcoding.rawValue)"
        }
    }
    return EmptyArrayString
}

/// 获取电影的下载链接
///
/// - Parameter request: 包含参数信息
/// - Returns: 下载链接json字符串
func getLinksByID(request: HTTPRequest) -> String {
    if let args = request.param(name: "id") {
        let movie = fetchDataByProcedure(name: "proc_download_get_by_movie_id", args: [args], columns: ["id", "url", "create_time"]) ?? []
        do {
            let json = try movie.jsonEncodedString()
            return json
        } catch {
            print("error json edncoding: \(error)")
            Log.info(message: "error json edncoding: \(error)")
            return "server error code: \(ErrorCode.jsonEcoding.rawValue)"
        }
    }
    return EmptyArrayString
}
