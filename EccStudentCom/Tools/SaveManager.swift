//
//  SaveManager.swift
//  EccStudentCom
//
//  Created by YutaKohashi on 2016/09/27.
//  Copyright © 2016年 YutaKohashi. All rights reserved.
//

import Foundation
import RealmSwift

class SaveManager{
    
    func saveAttendanceRate(_ realm:Realm ,mLastResponseHtml:String){
        
        var value:String = mLastResponseHtml.replacingOccurrences(of: "\r", with: "")
        value = value.replacingOccurrences(of: "\n", with: "")

        let narrowHtml :String = GetValuesBase("<table class=\"GridVeiwTable\"","</table>").narrowingValues(value)
        //教科ごと
        let results: [String] =  GetValuesBase("<tr>.*?</tr>").getGroupValues(narrowHtml)
        
        var item:String! = ""
        var rowCount = 0
        var firstRowFlg: Bool = true
        
        for row:String in results{
            let col: [String] =  GetValuesBase("<td.*?</td>").getGroupValues(row)
            
            let saveModel = SaveModel()
            
            firstRowFlg = true
            rowCount = 0
            for td:String in col{
                if(firstRowFlg){
                    //教科名を取得
                    saveModel.subjectName = GetValuesBase("<img(?:\\\".*?\\\"|\\'.*?\\'|[^\\'\\\"])*?>(.+?)</a>").getValues(td)
                    firstRowFlg = false
                    print("subjectName= \(saveModel.subjectName)")
                }else{
                    item = GetValuesBase("<font(?:\\\".*?\\\"|\\'.*?\\'|[^\\'\\\"])*?>(.+?)</font>").getValues(td)
                    item = GetValuesBase().removeNBSP(item)
                    item = GetValuesBase().removePercent(item)
                    
                    switch rowCount {
                    case 1:
                        saveModel.unit = item
                        print("unit= \(item)")
                    case 2:
                        saveModel.attendanceNumber = item
                        print("attendanceNumber= \(item)")
                    case 3:
                        saveModel.absentNumber = item
                        print("absentNumber= \(item)")
                    case 4:
                        saveModel.lateNumber = item
                        print("lateNumber= \(item)")
                    case 5:
                        saveModel.publicAbsentNumber1 = item
                        print("publicAbsentNumber1= \(item)")
                    case 6:
                        saveModel.publicAbsentNumber2 = item
                        print("publicAbsentNumber2= \(item)")
                    case 7:
                        saveModel.attendanceRate = item
                        print("attendanceRate= \(item)")
                    case 8:
                        saveModel.shortageNumber = item
                        print("shortageNumber= \(item)")
                    default:
                        print("default")
                    }
                }
                rowCount+=1
            }
            
            //データを保存
            try! realm.write {
                realm.add(saveModel)
            }
            print(" \("")")
            print("------------------- \("")")
            print(" \("")")
        }
    }
    
    // MARK:時間割をRealmを使用して保存するメソッド
    func saveTimeTable(_ realm:Realm ,mLastResponseHtml:String, teacherNames:[String]){
        var value:String = mLastResponseHtml.replacingOccurrences(of: "\r", with: "")
        value = value.replacingOccurrences(of: "\n", with: "")
        print(value)
        //時間割まわりを抽出
        let narrowHtml: String = GetValuesBase("<div id=\"timetable_col\" class=\"col\">","<div class=\"col\">").narrowingValues(value)
        print(narrowHtml)
        
        //行ごと 1時限,2時限,3時限,4時限
        let rowResults:[String] = GetValuesBase("<th class=\"term\">.*?</tr>").getGroupValues(narrowHtml)
        
        var rowNum = 0//行カウント
        var teacherIndex = 0
        for row:String in rowResults{
            
            
            //列ごと mon,tue,wed,thur,fri
            let col: [String] =  GetValuesBase("<td>.*?</td>").getGroupValues(row)
            var colNum = 0 //列カウント
            for td:String in col{
                let saveModel = TimeTableSaveModel()
                var subject:String = ""
                var room:String = ""
                var teacherName:String = ""
                
                if GetValuesBase("<li>").ContainsCheck(td){
                    subject = GetValuesBase("<li>(.+?)</li>").getValues(td)
                    room = GetValuesBase("<li>(.+?)</li>").getValues(td)
                    teacherName = teacherNames[teacherIndex]
                    teacherIndex += 1
                    
                    saveModel.subjectName = subject
                    saveModel.teacherName = teacherName
                    saveModel.room = room
                    saveModel.rowNum = rowNum
                    saveModel.colNum = colNum
                    
                }else{
                    //空のとき
                    saveModel.rowNum = rowNum
                    saveModel.colNum = colNum
                }
                
                //データを保存
                try! realm.write {
                    realm.add(saveModel)
                }
                colNum+=1
            }
            //行カウントをインクリメント
           rowNum+=1
        }
    }
    
    //スタブ　先生名を空文字で格納する
    // 将来的にはこのメソッドは不要
    func saveTimeTable(_ realm:Realm ,mLastResponseHtml:String){
        var value:String = mLastResponseHtml.replacingOccurrences(of: "\r", with: "")
        value = value.replacingOccurrences(of: "\n", with: "")
        //時間割まわりを抽出
        let narrowHtml: String = GetValuesBase("<div id=\"timetable_col\" class=\"col\">","<div class=\"col\">").narrowingValues(value)
        
        //行ごと 1時限,2時限,3時限,4時限
        let rowResults:[String] = GetValuesBase("<th class=\"term\">.*?</tr>").getGroupValues(narrowHtml)
        
        var rowNum = 0//行カウント
        var teacherIndex = 0
        var ignoreFlg :Bool = true
        for row:String in rowResults{
            // 1列目はヘッダのため無視
            if(ignoreFlg){
                ignoreFlg = false
                continue
            }
            //列ごと mon,tue,wed,thur,fri
            let col: [String] =  GetValuesBase("<td>.*?</td>").getGroupValues(row)
            var colNum = 0 //列カウント
            for td:String in col{
                let saveModel = TimeTableSaveModel()
                var subject:String = ""
                var room:String = ""
                let teacherName:String = ""
                
                if GetValuesBase("<li>").ContainsCheck(td){
                    subject = GetValuesBase("<li>(.+?)</li>").getValues(td)
                    room = GetValuesBase("<td>\\s*<ul>\\s*<li>.*?</li>\\s*<li>(.+?)</li>").getValues(td)
                    //teacherName = teacherNames[teacherIndex]
                    teacherIndex += 1
                    
                    saveModel.subjectName = subject
                    saveModel.teacherName = teacherName //teacherNameは空文字
                    saveModel.room = room
                    saveModel.rowNum = rowNum
                    saveModel.colNum = colNum
                    
                }else{
                    //空のとき
                    saveModel.rowNum = rowNum
                    saveModel.colNum = colNum
                }
                
                //*********************************************
                print("******************************")
                print("subject = " + subject)
                print("room = " + room)
                print("teacherName = " + teacherName)
                print("rowNum = " + String(rowNum))
                print("colNum = " + String(colNum))
                print("")
                print("")
                //*********************************************
                
                //データを保存
                try! realm.write {
                    realm.add(saveModel)
                }
                colNum+=1
            }
            //行カウントをインクリメント
            rowNum+=1
        }
    }
}
