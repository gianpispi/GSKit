//
//  ViewController.swift
//  Example
//
//  Created by Gianpiero Spinelli on 09/08/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import UIKit
import GSKit

class ViewController: GSViewController {
    
    var colors: [UIColor] = [.red, .green, .blue, .orange, .purple]
    var currentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeBackground(withColor: colors[currentIndex])
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleClick)))
    }
    
    @objc func handleClick() {
        currentIndex += 1
        
        if !colors.indices.contains(currentIndex) {
            currentIndex = 0
        }
        
        changeBackground(withColor: colors[currentIndex])
    }
}

