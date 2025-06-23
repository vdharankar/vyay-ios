//
//  ViewController.swift
//  vyay
//
//  Created by Vishal Dharankar on 06/06/24.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet var nameTextField : UITextField!
    @IBOutlet var emailTextField : UITextField!
    @IBOutlet var pwdTextField : UITextField!
    @IBOutlet var signupButton : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        styleControls()
    }
    
    func styleControls() {
        nameTextField.layer.cornerRadius = 10
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
            
        emailTextField.layer.cornerRadius = 10
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
        
        pwdTextField.layer.cornerRadius = 10
        pwdTextField.layer.borderWidth = 1
        pwdTextField.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
       
        signupButton.layer.cornerRadius = 25
    }
    
    @IBAction func onLogin( view : UIView) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {
            print("LoginViewController not found in storyboard")
            return
        }

        if #available(iOS 13.0, *) {
            guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
                print("SceneDelegate not found")
                return
            }
            sceneDelegate.window?.rootViewController = loginVC
            sceneDelegate.window?.makeKeyAndVisible()
        } else {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("AppDelegate not found")
                return
            }
            appDelegate.window?.rootViewController = loginVC
            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
    @IBAction func onRegister() {
        
    }


}

