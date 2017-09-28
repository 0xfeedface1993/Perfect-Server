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
import PerfectSessionMySQL

enum ErrorCode : Int {
    case jsonEcoding = 0x1
    case invalidateAuthrithe = 0x2
    case invalidateParameter = 0x3
    case serverError = 0x4
}

let EmptyArrayString = "{\"info\":\"sorry, no data\", \"code\":\"200\"}"

func apiSpaHandler() throws -> RequestHandler {
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
            case "registerAccount":
                response.appendBody(string: register(request: request))
                break
            case "login":
                response.appendBody(string: login(request: request))
                break
            case "loginOut":
                response.appendBody(string: loginOut(request: request))
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
    guard checkLoginSession(request: request) else {
        return EmptyArrayString
    }
    // {"title":"", "page":"", "pics":["", "", ""], "downloads":["", "", ""]}
    //  IN p_msk varchar(20),  IN p_movie_time varchar(20),  IN p_formart varchar(20),  IN p_size varchar(20)
    if let str = request.postBodyString, let userid = request.session?.userid {
        do {
            guard let json = try str.jsonDecode() as? [String:Any] else {
                return errorMaker(code: .invalidateParameter, info: "您的参数有误")
            }
            if let title = json["title"] as? String,
                let page = json["page"] as? String,
                let pics = json["pics"] as? [String],
                let msk = json["msk"] as? String,
                let time = json["time"] as? String,
                let format = json["format"] as? String,
                let size = json["size"] as? String,
                let downloads = json["downloads"] as? [String],
                let results = fetchDataByProcedure(name: "proc_moive_add", args: ["\(title)", "\(page)", "\(userid)", msk, time, format, size], columns: ["movie_id"]), results.count > 0,
                let first = results[0]["movie_id"] as? String {
                
                let tasks = downloads.map({
                    item in
                    return Procedure(name: "proc_download_add", args: ["'\(item)'", "'\(first)'"], colmns:  ["id"])
                }) + pics.map({
                    item in
                    return Procedure(name: "proc_image_add", args: ["'\(first)'", "'\(item)'"], colmns:  ["id"])
                })
                
                let _ = updateByProcedures(procedures: tasks)
                
                return try! ["movieID":first].jsonEncodedString()
            }   else    {
                return EmptyArrayString
            }
            
        }   catch   {
            Log.info(message: "error json decoding: \(error)")
            print("json decode failed!")
            return errorMaker(code: .jsonEcoding, info: error.localizedDescription)
        }
    }
    return EmptyArrayString
}

func getMovieByID(request: HTTPRequest) -> String {
    guard checkLoginSession(request: request) else {
        return EmptyArrayString
    }
    if let args = request.param(name: "id")?.characters.split(separator: "|").map({String($0)}) {
        let movie = fetchDataByProcedure(name: "proc_moive_get_by_id", args: args, columns: ["id", "title", "page", "msk", "time", "format", "size"]) ?? []
        do {
//            Log.info(message: request.session?.userid ?? "")
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
    guard checkLoginSession(request: request) else {
        return EmptyArrayString
    }
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
    guard checkLoginSession(request: request) else {
        return EmptyArrayString
    }
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


/// 注册账号
///
/// - Parameter request: 包含参数信息
/// - Returns: 包含注册成功账号字符串
func register(request: HTTPRequest) -> String {
    if let account = request.param(name: "account"), let pwd = request.param(name: "password"), let base64 = [UInt8](randomCount: 64).encode(.base64), let randomNumberBase64Str = String(validatingUTF8: base64) {
        let users = fetchDataByProcedure(name: "proc_account_add", args: [account, (pwd + randomNumberBase64Str).sha256(), randomNumberBase64Str], columns: ["user_id"]) ?? []
        do {
            let json = try users.jsonEncodedString()
            return json
        } catch {
            print("error json edncoding: \(error)")
            Log.info(message: "error json edncoding: \(error)")
            return "server error code: \(ErrorCode.jsonEcoding.rawValue)"
        }
    }
    return EmptyArrayString
}


/// 登录
///
/// - Parameter request: 包含参数信息
/// - Returns: 包含登录结果字符串
func login(request: HTTPRequest) -> String {
    if let account = request.param(name: "account"), let pwd = request.param(name: "password") {
        let info = fetchDataByProcedure(name: "proc_login", args: [account], columns: ["passwod", "salt", "name"]) ?? []
        do {
            for data in info {
                if let passwod = data["passwod"] as? String, let salt = data["salt"] as? String, let name = data["name"], (pwd + salt).sha256() == passwod {
//                    Log.info(message: "pwd: \(pwd) \nsalt: \(salt) \n caculateSha256: \((pwd + salt).sha256()) \nsave: \(passwod)")
                    request.session?.userid = account
                    return try ["id":account, "name":name, "info":"人生得意须尽欢"].jsonEncodedString()
                }
            }
            return errorMaker(code: .invalidateAuthrithe, info: "账号或密码不正确")
        } catch {
            print("error json edncoding: \(error)")
            Log.info(message: "error json edncoding: \(error)")
            return errorMaker(code: .jsonEcoding, info: error.localizedDescription)
        }
    }
    return EmptyArrayString
}


/// 退出登录
///
/// - Parameter request: 包含账户信息
/// - Returns: 退出登录成功则返回 code 200
func loginOut(request: HTTPRequest) -> String {
    if let account = request.param(name: "account"), let userid = request.session?.userid, userid == account {
        do {
            request.session?.userid = ""
            return try [["info":"退出登录成功", "code":"200"]].jsonEncodedString()
        } catch {
            print("error json edncoding: \(error)")
            Log.info(message: "error json edncoding: \(error)")
            return "server error code: \(ErrorCode.jsonEcoding.rawValue)"
        }
    }
    return EmptyArrayString
}


/// 检查session
///
/// - Parameter request: 包含session请求
/// - Returns: 已登录为true，否则为false
func checkLoginSession(request: HTTPRequest) -> Bool {
    if let session = request.session {
        let info = fetchDataByProcedure(name: "proc_account_validate", args: [session.userid], columns: ["state"]) ?? []
        for data in info {
            if let state = data["state"] as? String {
                return state == "\u{01}"
            }
        }
    }
    return false
}

func errorMaker(code: ErrorCode, info: String) -> String {
    return try! ["info":info, "code":code.rawValue].jsonEncodedString()
}
