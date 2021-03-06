//
//  HttpHelper.swift
//  EccStudentCom
//
//  Created by YutaKohashi on 2016/11/09.
//  Copyright © 2016年 YutaKohashi. All rights reserved.
//

import Foundation
import RealmSwift

class HttpHelper:HttpBase{
    
    let URL = RequestURL()
    let BODY = RequestBody()
    
    // MARK:時間割を更新
    func getTimeTable(userId :String,password:String,callback: @escaping (Bool) -> Void) -> Void {
        // 時間割
        self.requestTimeTable(userId: userId, password: password,callback: {
            requestResult in
            
            if(requestResult.bool){
                sleep(2)
                //保存処理
                let realmSwift = try! Realm()
                //データを削除
                let savemodels = realmSwift.objects(TimeTableSaveModel.self)
                savemodels.forEach({ (model) in
                    try! realmSwift.write() {
                        realmSwift.delete(model)
                    }
                })
                SaveManager().saveTimeTable(realmSwift,mLastResponseHtml: requestResult.string)
            }
            callback(requestResult.bool)
        })
    }
    
    // MARK:出席照会リスト
    func getAttendanceRate(userId :String,password:String,callback: @escaping (Bool) -> Void) -> Void {
        self.reequestAttendanseRate(userId: userId, password: password) { (requestResult) in
            
            if(requestResult.bool){
                //Realmをインスタンス化
                let realm = try! Realm()
                //一度データを削除
                let savemodels = realm.objects(SaveModel.self)
                savemodels.forEach({ (model) in
                    try! realm.write() {
                        realm.delete(model)
                    }
                })
                SaveManager().saveAttendanceRate(realm,mLastResponseHtml: requestResult.string)
            }
            callback(requestResult.bool)
        }
    }
    
    // MARK:時間割と出席照会を取得し保存するメソッド
    func getTimeTableAttendanceRate(userId :String,password:String,callback: @escaping (Bool) -> Void) -> Void {
        getTimeTable(userId: userId, password: password) { (cb1) in
            if(cb1){
                self.getAttendanceRate(userId: userId, password: password, callback:
                    { (cb2) in
                        callback(cb2)
                })
            }else{callback(cb1)}
        }
    }
    
    // MARK: -
    // MARK:時間割を取得
    private func requestTimeTable(userId :String,password:String,callback: @escaping (CallBackClass) -> Void) -> Void {
        httpGet(url: URL.ESC_TO_PAGE,
                requestBody:"" ,
                referer: URL.DEFAULT_REFERER,
                header: true)
        { (cb1) in
            if(cb1.bool){
                self.httpPost(url: self.URL.ESC_LOGIN,
                              requestBody: self.BODY.createPostDataForEscLogin(userId: userId,
                                                                               passwrod: password,
                                                                               mLastResponseHtml: cb1.string),
                              referer: self.URL.ESC_TO_PAGE,
                              header: true)
                { (cb2) in
                    callback(cb2)
                }
            }else{callback(cb1)} //false
        }
    }
    
    // MARK:出席率を取得
    private func reequestAttendanseRate(userId :String,password:String,callback: @escaping (CallBackClass) -> Void) -> Void {
        httpGet(url: URL.YS_TO_PAGE,
                requestBody:"" ,
                referer: URL.DEFAULT_REFERER,
                header: true)
        { (cb1) in
            if(cb1.bool){
                self.httpPost(url: self.URL.YS_LOGIN,
                              requestBody: self.BODY.createPostDataForYSLogin(userId:userId,
                                                                              password:password,
                                                                              mLastResponseHtml: cb1.string),
                              referer: self.URL.YS_TO_PAGE,
                              header: true)
                { (cb2) in
                    if(cb2.bool){
                        self.httpPost(url: self.URL.YS_TO_RATE_PAGE,
                                      requestBody: self.BODY.createPostDataForRatePage(mLastResponseHtml: cb2.string),
                                      referer: self.URL.YS_LOGIN,
                                      header: false)
                        { (cb3) in
                            //正常に遷移できているか確認
                            if !GetValuesBase("教科名").ContainsCheck(cb3.string){
                                cb3.bool = false
                                callback(cb3)
                                print(cb3.string)
                                return;
                            }
                            callback(cb3)
                        }
                    }else{callback(cb2)} //false
                }
            }else{callback(cb1)} //false
        }
    }
}
