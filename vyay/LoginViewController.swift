//
//  LoginViewController.swift
//  vyay
//
//  Created by Vishal Dharankar on 07/06/24.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet var emailTextField : UITextField!
    @IBOutlet var pwdTextField : UITextField!
    @IBOutlet var signupButton : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        styleControls()
    }
    
    func styleControls() {
            
        emailTextField.layer.cornerRadius = 10
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
        
        pwdTextField.layer.cornerRadius = 10
        pwdTextField.layer.borderWidth = 1
        pwdTextField.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
       
        signupButton.layer.cornerRadius = 25
    }
    
    
    @IBAction func onRegister() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mainVC = mainStoryboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController else {
            print("LoginViewController not found in storyboard")
            return
        }

        if #available(iOS 13.0, *) {
            guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
                print("SceneDelegate not found")
                return
            }
            sceneDelegate.window?.rootViewController = mainVC
            sceneDelegate.window?.makeKeyAndVisible()
        } else {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("AppDelegate not found")
                return
            }
            appDelegate.window?.rootViewController = mainVC
            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
    @IBAction func onLogin() {
        let navigationController = storyboard!.instantiateViewController(identifier: "NavigationController") as! UINavigationController
           
        if #available(iOS 13.0, *) {
            guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
                print("SceneDelegate not found")
                return
            }
            sceneDelegate.window?.rootViewController = navigationController
            sceneDelegate.window?.makeKeyAndVisible()
        } else {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("AppDelegate not found")
                return
            }
            appDelegate.window?.rootViewController = navigationController
            appDelegate.window?.makeKeyAndVisible()
        }
           
    }
   

}
