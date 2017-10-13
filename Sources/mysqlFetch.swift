//
//  mysql.swift
//  PerfectTemplate
//
//  Created by virus1993 on 2017/6/30.
//
//

import PerfectLib
import MySQL
import PerfectHTTP
import PerfectHTTPServer

let testHost = "127.0.0.1"
let testUser = "admin"
let testPassword = "Admin@20170620"
let testDB = "sex8_data_test_chi"

struct Procedure {
    var name:String
    var args:[String]
    var clomns:[String]
    init(name: String, args: [String], colmns: [String]) {
        self.name = name
        self.args = args
        self.clomns = colmns
    }
}

func updateByProcedures(procedures: [Procedure]) -> String? {
    guard let mysql = connectDatabase() else {
        return nil
    }
    
    //Choose the database to work with
    for proc in procedures {
        let statement = "CALL \(proc.name)(\(proc.args.joined(separator: ",")));"
        print("statement: " + statement)
        let querySuccess = mysql.query(statement: statement)
        
        // make sure the query worked
        guard querySuccess else {
            Log.info(message: "Failure: \(mysql.errorCode()) \(mysql.errorMessage())")
            print("querySuccess Failure: \(mysql.errorCode()) \(mysql.errorMessage())")
            return nil
        }
    }
    
    return EmptyArrayString
}


/// 链接数据库
///
/// - Returns: 数据库实例，链接失败返回nil
func connectDatabase() -> MySQL? {
     // Create an instance of MySQL to work with
    let mysql = MySQL()
    let connected = mysql.connect(host: testHost, user: testUser, password: testPassword, db: testDB, port: 3306)
    guard connected else {
        // verify we connected successfully
        print(mysql.errorMessage())
        return nil
    }
    return mysql
}

/// 调用存过，并传递参数
///
/// - Parameters:
///   - name: 存过名
///   - args: 参数，根据顺序排列
///   - columns: 返回值需要的列名，按结果集的列名顺序
/// - Returns: 返回包含columns指定的列名的数组，数组元素是字典，根据列明取值，值可能是nil；
///            返回nil，说明执行存过出错
func fetchDataByProcedure(name: String, args: [String], columns: [String]) -> [[String:String]]? {
    guard let mysql = connectDatabase() else {
        return nil
    }
    
    //Choose the database to work with
    let statement = "CALL \(name)(\(args.map({ "'\($0)'" }).joined(separator: ",")));"
    print("statement: " + statement)
    let querySuccess = mysql.query(statement: statement)
    
    // make sure the query worked
    guard querySuccess else {
        Log.info(message: "Failure: \(mysql.errorCode()) \(mysql.errorMessage())")
        return nil
    }
    
    // Save the results to use during this session
    guard let results = mysql.storeResults() else {
        return []
    } //We can implicitly unwrap because of the guard on the querySuccess. You’re welcome to use an if-let here if you like.
    
    var pack = [[String:String]]()
    
    results.forEachRow { row in
        var land = [String:String]()
        for (index, key) in columns.enumerated() {
            land[key] = row[index] ?? ""
        }
        pack.append(land)
    }
    
    return pack
}

func fetchDataBySQL(statement: String, columns: [String]) -> [[String:String?]]? {
    guard let mysql = connectDatabase() else {
        return nil
    }
    
    let querySuccess = mysql.query(statement: statement)
    // make sure the query worked
    guard querySuccess else {
        Log.info(message: "Failure: \(mysql.errorCode()) \(mysql.errorMessage())")
        return nil
    }
    
    // Save the results to use during this session
    let results = mysql.storeResults()! //We can implicitly unwrap because of the guard on the querySuccess. You’re welcome to use an if-let here if you like.
    
    var pack = [[String:String?]]()
    
    results.forEachRow { row in
        var land = [String:String?]()
        for (index, key) in columns.enumerated() {
            land[key] = row[index] ?? ""
        }
        pack.append(land)
    }
    
    return pack
}
