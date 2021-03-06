//
//  PreferenceController.swift
//  EccStudentCom
//
//  Created by YutaKohashi on 2016/11/02.
//  Copyright © 2016年 YutaKohashi. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift


class PreferenceController : UITableViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let btn_back = UIBarButtonItem()
        btn_back.title = ""
        self.navigationItem.backBarButtonItem = btn_back
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //完了ボタンが押下されたとき
    @IBAction func doneButtonClick(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell #\(indexPath.row)!")
        
        switch indexPath.section {
        case 0:
            if(indexPath.row == 0){
                
                //インターネットに接続されていないのときはアラート表示
                if !ToolsBase().CheckReachability("google.com"){
                    DialogManager().showWarningForInternet()
                    return;
                }
                
                DialogManager().showIndicator()
                HttpConnector().request(type: .TIME_TABLE,
                                        userId: PreferenceManager().getSavedId(),
                                        password: PreferenceManager().getSavedPass(),
                                        callback:
                    { (result) in
                        if(result){
                            DialogManager().hideIndicator()
                            let sec:Double = 0.8
                            let delay = sec * Double(NSEC_PER_SEC)
                            let time  = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                                DialogManager().showSuccess()
                            })
                        }
                        else
                        {
                            DialogManager().hideIndicator()
                            let sec:Double = 0.8
                            let delay = sec * Double(NSEC_PER_SEC)
                            let time  = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                                DialogManager().showError()
                            })
                        }
                        
                })
            }
            break
        case 1:
            //セクションを削除追加することで変化するので注意
            if (indexPath.row == 0){
                //ログアウト
                logout()
            }
            break
        case 2:
            
            break
        default:
            break
            
        }
        //タップしたあとハイライトを消す
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override var prefersStatusBarHidden : Bool {
        // trueの場合はステータスバー非表示
        return false;
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        // ステータスバーを白くする
        return UIStatusBarStyle.lightContent;
    }
    
    // ログアウト
    func logout(){
        let alert: UIAlertController = UIAlertController(title: "確認",
                                                         message: "ログアウトしてもよろしいですか？",
                                                         preferredStyle:   UIAlertControllerStyle.alert)
        // OKボタン
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{
            (action: UIAlertAction!) -> Void in
            print("OK")
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }
            
            PreferenceManager().saveLoginState(false)
            //保存されていたpassIdを削除
            PreferenceManager().removeSavedIdPass()
            
            DispatchQueue.main.async(execute: {
                //View controller code
                let storyboard: UIStoryboard = self.storyboard!
                let nextView = storyboard.instantiateViewController(withIdentifier: "LoginView") as! ViewController
                self.present(nextView, animated: true, completion: nil)
            })
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler:{
            (action: UIAlertAction!) -> Void in
            print("Cancel")
        })
        
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        present(alert, animated: true, completion: nil)
    }
}
