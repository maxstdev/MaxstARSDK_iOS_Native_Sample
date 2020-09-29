//
//  SettingTableViewController.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 12..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {
    @IBOutlet var resolution640: UISwitch!
    @IBOutlet var resolution1280: UISwitch!
    @IBOutlet var resolution1920: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let resolution:Int = getSavedCameraResolution()
        
        if resolution == 640 {
            resolution640.setOn(true, animated: true)
            resolution1280.setOn(false, animated: true)
            resolution1920.setOn(false, animated: true)
        } else if resolution == 1280 {
            resolution640.setOn(false, animated: true)
            resolution1280.setOn(true, animated: true)
            resolution1920.setOn(false, animated: true)
        } else if resolution == 1920 {
            resolution640.setOn(false, animated: true)
            resolution1280.setOn(false, animated: true)
            resolution1920.setOn(true, animated: true)
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @IBAction func changeSwitch640(_ sender: Any) {
        if resolution640.isOn {
            resolution640.setOn(true, animated: true)
            resolution1280.setOn(false, animated: true)
            resolution1920.setOn(false, animated: true)
            saveCameraResolution(resolution: 640)
        }
    }
  
    @IBAction func changeSwitch1280(_ sender: Any) {
        if resolution1280.isOn {
            resolution640.setOn(false, animated: true)
            resolution1280.setOn(true, animated: true)
            resolution1920.setOn(false, animated: true)
            saveCameraResolution(resolution: 1280)
        }
    }
    
    @IBAction func changeSwitch1920(_ sender: Any) {
        if resolution1920.isOn {
            resolution640.setOn(false, animated: true)
            resolution1280.setOn(false, animated: true)
            resolution1920.setOn(true, animated: true)
            saveCameraResolution(resolution: 1920)
        }
    }
    
    func saveCameraResolution(resolution:Int) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(resolution, forKey: "CameraResolution")
    }
    
    func getSavedCameraResolution() -> Int {
        let userDefaults:UserDefaults = UserDefaults.standard
        let resolution:Int = userDefaults.integer(forKey: "CameraResolution")
        return resolution
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
