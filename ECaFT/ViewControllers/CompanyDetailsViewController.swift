//
//  CompanyDetailsViewController.swift
//  ECaFT
//
//  Created by Amanda Ong on 1/6/17.
//  Copyright © 2017 ECAFT. All rights reserved.
//

import UIKit


class CompanyDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let screenSize : CGRect = UIScreen.main.bounds
    var tableView = UITableView()
    var headerView = UIView()
    var company: Company!
    
    var infoSC = CompanyViewModel()
    
    //Table view properties
    var name = UILabel() //company name
    var isFavorite : Bool = false
    var location = UILabel() //company booth location
    var favoritesButton = UIButton()
    
    //segmented control
    let segmentTitles : [String] = ["Company Info", "Notes"]
    var segControl = UISegmentedControl()
    
    //Sections in "Company Info"
    let compInfoSectionTitles : [String] = ["Company Information", "Open Positions", "Majors of Interest", "Sponsorship", "OPT/CPT"]
    var compInfoNumOfSections = 5 //number of sections in "Company Info"
    
    //Sections in "Notes"
    let notesSectionTitles : [String] = ["Notes", "Photos"]
    var notesNumOfSections = 2 //number of sections in "Notes"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navBarAndStatusBarHeight = (self.navigationController?.navigationBar.frame.size.height)!+UIApplication.shared.statusBarFrame.height
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height - navBarAndStatusBarHeight), style: UITableViewStyle.plain) //sets tableview to size of view below status bar and nav bar
        tableView.delegate      =   self
        tableView.dataSource    =   self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none //removes cell lines
        
        //Regsiter custom cells and xib files
        tableView.register(CompanyInfoTableViewCell.self, forCellReuseIdentifier: "CompanyInfoTableViewCell")
        //tableView.register(ListTableViewCell.self, forCellReuseIdentifier: "ListTableViewCell")
        tableView.register(UINib(nibName: "ListTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "ListTableViewCell")
        tableView.register(textViewTableViewCell.self, forCellReuseIdentifier: "textViewTableViewCell")
        tableView.register(UINib(nibName: "NotesTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "NotesTableViewCell")

        //Register notification observer for when keyboard shows & hides
        NotificationCenter.default.addObserver(self, selector: #selector(CompanyDetailsViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CompanyDetailsViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        self.view.addSubview(self.tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        createHeaderView() //put method in viewWillAppear so information updated depending on what company is tapped
        if let favs = UserDefaults.standard.object(forKey: Property.favorites.rawValue) as? Data {
            infoSC.favoritesString = NSKeyedUnarchiver.unarchiveObject(with: favs) as! [String]
        }
    }
  
    func createHeaderView() {
        headerView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 200))
        headerView.backgroundColor = UIColor.white
        tableView.tableHeaderView = headerView
        
        //Add image view
        let imageView = UIImageView(frame: CGRect(x:0, y:0, width:110, height:110))
        imageView.center.y = 0.375*(self.tableView.tableHeaderView?.frame.height)!
        imageView.center.x = 0.2*self.screenSize.width
        imageView.image = company.image
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        self.tableView.tableHeaderView?.addSubview(imageView)
        
        //Create name label
        name = UILabel(frame: CGRect(x: 0.43*screenSize.width, y: 0, width: screenSize.width*0.58, height: 21)) //same x value as location so name & location label are aligned
        name.center.y = 0.18*(self.tableView.tableHeaderView?.frame.height)!
        name.textAlignment = NSTextAlignment.left
        name.text = company.name
        name.font = UIFont.boldSystemFont(ofSize: 20)
        
        //Make name into go into another line if necessary
        name.numberOfLines = 0 //set num of lines to infinity
        name.lineBreakMode = .byWordWrapping
        name.sizeToFit()
        self.tableView.tableHeaderView?.addSubview(name)
        
        //Create booth location label
        location = UILabel(frame: CGRect(x: 0.43*screenSize.width, y: 0, width: screenSize.width*0.75, height: 21))
        location.textAlignment = NSTextAlignment.left
        location.font = UIFont.systemFont(ofSize: 18)
        location.textColor = UIColor.ecaftDarkGray
        location.text = "Booth " + company.location
        self.tableView.tableHeaderView?.addSubview(location)


        //Create favorites button
        favoritesButton.setTitleColor(UIColor.ecaftGold, for: .normal)
        favoritesButton.frame = CGRect(x: 0.38*screenSize.width, y: 0, width: 0.5*screenSize.width, height: 50)
        if(screenSize.height < 667.0) { //iPhone 5s & below
            favoritesButton.frame = CGRect(x: 0.41*screenSize.width, y: 0, width: 0.5*screenSize.width, height: 50)
        }
        favoritesButton.addTarget(self, action: #selector(CompanyDetailsViewController.favoritesButtonPressed(button:)), for: .touchUpInside)
        
        //Move text to left of button image
        favoritesButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        favoritesButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        favoritesButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        favoritesButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        favoritesButton.centerTextAndImage(spacing: 10)
        
        if (isFavorite) { setUpFavorite() }
        else { setUpNotFavorite() }
        
        self.tableView.tableHeaderView?.addSubview(favoritesButton)
        
        //Create segmented control
        segControl = UISegmentedControl(items: segmentTitles)
        segControl.selectedSegmentIndex = 0
        
        segControl.frame = CGRect(x: 0.25*screenSize.width, y: (self.tableView.tableHeaderView?.frame.height)! - 38, width: screenSize.width*0.5, height: 26)
        segControl.center.x = 0.5*self.screenSize.width
        segControl.layer.cornerRadius = 5.0
        segControl.backgroundColor = UIColor.white
        segControl.tintColor = UIColor.ecaftRed
        
        segControl.addTarget(self, action: #selector(CompanyDetailsViewController.segmentControlHandler(sender:)), for: .valueChanged)
        
        self.tableView.tableHeaderView?.addSubview(segControl)
        
        //Calculate num of lines for company name label & adjust booth location label accordingly
        let numLines = Int(name.frame.size.height/name.font.ascender) //Divide height of multiline label by line height of UILabel's font (from text to top of label's frame)
        if (numLines < 2) {
            location.center.y = 0.38*(self.tableView.tableHeaderView?.frame.height)!
            favoritesButton.center.y = 0.57*(self.tableView.tableHeaderView?.frame.height)!
        } else if (numLines == 2){
            location.center.y = 0.53*(self.tableView.tableHeaderView?.frame.height)!
            favoritesButton.center.y = 0.69*(self.tableView.tableHeaderView?.frame.height)!
        } else { //numLines is 3
            location.center.y = 0.66*(self.tableView.tableHeaderView?.frame.height)!
            favoritesButton.center.y = 0.83*(self.tableView.tableHeaderView?.frame.height)!
        }
    }
    
    @objc func favoritesButtonPressed(button: UIButton!) {
        //Add to favorites data list and change uibutton image to filled in star
         if (!isFavorite) { //wants to add company
            setUpFavorite()
            infoSC.favoritesString.append(name.text!)
            isFavorite = true
         }
         else { //wants to remove company
            setUpNotFavorite()
            if let i = infoSC.favoritesString.index(of: name.text!) {
                infoSC.favoritesString.remove(at: i)
            }
            isFavorite = false
         }
        
        UserDefaults.standard.removeObject(forKey: Property.favorites.rawValue)
        let savedData = NSKeyedArchiver.archivedData(withRootObject: infoSC.favoritesString)
        UserDefaults.standard.set(savedData, forKey: Property.favorites.rawValue)
    }
    
    @IBAction func segmentControlHandler(sender: UISegmentedControl){
        //Handler for when custom Segmented Control changes and will change the content of the following table depending on the value selected
        print("Selected segment index is: \(sender.selectedSegmentIndex)")
        tableView.reloadData()
    }
    
    func setUpFavorite() {
        favoritesButton.setImage(#imageLiteral(resourceName: "favoritesFilled"), for: .normal)
        favoritesButton.setTitle("Remove favorites", for: .normal)
    }
    
    func setUpNotFavorite() {
        favoritesButton.setImage(#imageLiteral(resourceName: "favorites"), for: .normal)
        favoritesButton.setTitle("Add to favorites", for: .normal)
    }
    
    /*****-------KEYBOARD: Prevent keyboard from hiding notes text view-----*****/
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: {
            // For some reason adding inset in keyboardWillShow is animated by itself but removing is not, that's why we have to use animateWithDuration here
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        })
    }
    
    /*****------------------------------TABLE VIEW METHODS------------------------------*****/
    //Section: Set number of sections and section headers
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections = compInfoNumOfSections
        
        switch(segControl.selectedSegmentIndex){
        
        case 1:
            numOfSections = notesNumOfSections
            
        default:
            numOfSections = compInfoNumOfSections
        }
        
        return numOfSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitles : [String] = compInfoSectionTitles
        
        switch(segControl.selectedSegmentIndex){
            
        case 1:
            sectionTitles = notesSectionTitles
            
        default:
            sectionTitles = compInfoSectionTitles
        }
        
        return sectionTitles[section]
    }

    //Section: Change font color and background color for section headers
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 25))
        returnedView.backgroundColor = UIColor.ecaftLightGray
        
        let label = UILabel(frame: CGRect(x: 0.05*screenSize.width, y: 0, width: screenSize.width, height: 25))
        label.center.y = 0.5*label.frame.height
        //label.text = sectionTitles[section]
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.textColor = .ecaftDarkGray
        
        switch(segControl.selectedSegmentIndex){
            
        case 1:
            label.text = notesSectionTitles[section]
            
        default:
            label.text = compInfoSectionTitles[section]
        }
        
        returnedView.addSubview(label)
        
        return returnedView
    }

    //Rows: Set num of rows per section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if(segControl.selectedSegmentIndex==1) {  //"Notes" page
            return 1 //for Notes sect and Photos sect
        }
        else {  //"Company Info" page
            if(section == 0) { //Company information sect
                return 1
            }
            else if (section == 1) { //Open positions sect
                return company.positions.count + 2
            }
            else if (section == 2) { //Majors sect
                return company.majors.count + 2
            } else { //Sponsorship sect, OPT/CPT sect
                return 1
            }
        }
    }
    
    //Rows: Set height for each row    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        var height:CGFloat = 120.0
        if(segControl.selectedSegmentIndex==1) {  //"Notes" page
            height = 200.0 //for Notes sect and Photos sect
        }
        else {  //"Company Info" page
            if(indexPath.section == 0) { //company info section
                height = 200.0
            } else if(indexPath.section == 1) { //open positions section
                if(indexPath.row==0 || indexPath.row==company.positions.count+1) {
                    height = 5.0
                } else {
                    height = 40.0
                }
            } else if(indexPath.section == 2) { //majors of interest section
                if(indexPath.row==0 || indexPath.row==company.majors.count+1) {
                    height = 5.0
                } else {
                    height = 40.0
                }
            } else if (indexPath.section == 3) { //sponsorship section (3)
                height = 60.0
            } else if (indexPath.section == 4) { //OPT/CPT section (4)
                height = 60.0
            }
            else { //default (Can delete or make OPT/CPT section height into 310)
                height = 310.0
            }
        }
        return height
    }
    
    //Table: Load in custom cells
    let customCellIdentifier = [0: "CompanyInfoTableViewCell", 1 : "ListTableViewCell", 2 : "ListTableViewCell", 3 : "textViewTableViewCell", 4 : "textViewTableViewCell"]
    let notesCustomCellIdentifier = [0: "NotesTableViewCell", 1: "NotesTableViewCell"] //NEED TO CREATE NEW TABLEVIEW CELL FOR PHOTOS SECTION
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var identifier = customCellIdentifier[indexPath.section]
        if(segControl.selectedSegmentIndex==1) {
            identifier = notesCustomCellIdentifier[indexPath.section]
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath)
        
        //Remove left indent for text in cell
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        //Removes grey highlight over cells
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        if identifier == customCellIdentifier[0] {
            let customCell = cell as! CompanyInfoTableViewCell
            customCell.information = company.information
            customCell.websiteLink = company.website
            return customCell
        } else if identifier == customCellIdentifier[1] {
            let customCell = cell as! ListTableViewCell
            if(indexPath.section == 1) {
                if(indexPath.row > 0 && indexPath.row < company.positions.count+1){
                    customCell.itemLabel.text = company.positions[indexPath.row-1]
                }
            }
            if(indexPath.section == 2) {
                if(indexPath.row > 0 && indexPath.row < company.majors.count+1){
                    customCell.itemLabel.text = company.majors[indexPath.row-1]
                }
            }
            return customCell
        } else if (identifier == customCellIdentifier[3] || identifier == customCellIdentifier[4]) {
            let customCell = cell as! textViewTableViewCell
            if(indexPath.section == 3) {
                print("does sponsor: \(company.sponsor)")
                if(company.sponsor) {
                    customCell.bodyTextView.text = "The company can sponsor the candidate"
                } else {
                    customCell.bodyTextView.text = "The company cannot sponsor the candidate"
                }
            } else if (indexPath.section == 4) {
                if(company.optcpt) {
                    customCell.bodyTextView.text = "The company accepts opt/cpt"
                } else {
                    customCell.bodyTextView.text = "The company does not accept opt/cpt"
                }
            }
            return customCell
        }
        else {  //applies to "Notes" page. Change up later to implement photos section
            let customCell = cell as! NotesTableViewCell
            customCell.companyName = company.name
            customCell.notesTextView.tag = indexPath.row
            customCell.placeholderText = "Takes notes about \(company.name) here"
            
            if let savedNote = UserDefaults.standard.string(forKey: company.name) {
                customCell.notesTextView.text = savedNote
            }
            if (customCell.notesTextView.text == "") {
                customCell.applyPlaceholderStyle(customCell.notesTextView, placeholderText: customCell.placeholderText)
            }
            //set up cell & return cell
            return customCell
        }
    }
    
    
    //Table: Stop table cell turning grey when click on cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
}

