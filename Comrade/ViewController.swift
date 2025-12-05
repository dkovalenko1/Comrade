//
//  ViewController.swift
//  Comrade
//
//  Created by david on 05.12.2025.
//

import UIKit

class ViewController: UIViewController {

    let test = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        test.text = "Hello, Team!"
        test.textAlignment = .center
        test.textColor = .black
        test.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        test.frame = view.bounds.insetBy(dx: 20, dy: 100)
        view.addSubview(test)
    }

}

