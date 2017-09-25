

import UIKit

class FiltersViewController: BaseController {
    @IBOutlet var checkViews: [UIView]!
    @IBOutlet var filtersButton: [UIButton]!
    @IBOutlet var healthButtons: [UIButton]!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var caloriesFromTextField: UITextField!
    @IBOutlet weak var caloriesToTextField: UITextField!
    @IBOutlet weak var ingredientsUpToTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    let array:Array = HealthFilters.allValue
    
    var filterArray:Array<String> = []
    var healthArray:Array<String> = []
    var item = FoodApiModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapForHideKeyboard()
        setupUI()
}

   func setupUI() {
    navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    navigationController?.navigationBar.shadowImage = UIImage()
    navigationController?.navigationBar.isTranslucent = true
    navigationController?.view.backgroundColor = UIColor.clear
    
    searchTextField.layer.masksToBounds = false
    searchTextField.layer.shadowColor = UIColor.black.cgColor
    searchTextField.layer.shadowOffset = CGSize.init(width: 0, height: 0)
    searchTextField.layer.shadowOpacity = 0.4
    searchTextField.layer.shadowRadius = 3.0
    setupCheckViewsUI()
    
    doneButton.isEnabled = false
    doneButton.alpha = 0.6
    

    addDoneButton()

    }

    private func setupCheckViewsUI() {
        for checkView in checkViews {
            checkView.layer.borderWidth = 1.0
            checkView.layer.borderColor = GradientColor.teal.cgColor
        }
    }
    
    //MARK: - Action -
    
    @IBAction func filterSelected(_ sender: UIButton) {
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: (sender.titleLabel?.text)!)
        if sender.isSelected {
            for view in checkViews {
                if sender.tag == view.tag {
                    view.layer.sublayers = nil
                }
            }
            sender.isSelected = false
            attributeString.removeAttribute(NSStrikethroughStyleAttributeName, range: NSRangeFromString((sender.titleLabel?.text)!))
            sender.titleLabel?.attributedText = attributeString
        }else {
            sender.isSelected = true
            for view in checkViews {
                if sender.tag == view.tag {
                    let gradient = CAGradientLayer()
                    gradient.frame = view.bounds
                    gradient.colors = GradientColor.colors
                        view.layer.insertSublayer(gradient, at: 0)
                }
            }
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributeString.length))
            sender.titleLabel?.attributedText = attributeString
                    }
    }
    
    @IBAction func doneAction(_ sender: UIButton) {
        router.feed.presentRecipesSearchListWithFilters(true, performItemCreation())
    }
    
    @IBAction func searchTextFieldChange(_ sender: UITextField) {
        if (searchTextField.text?.isEmpty)! {
            doneButton.isEnabled = false
            doneButton.alpha = 0.6
        } else {
            doneButton.isEnabled = true
            doneButton.alpha = 1
        }
    }
    
    //MARK: - Private -
    
    private func addDoneButton() {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                            target: view, action: #selector(UIView.endEditing(_:)))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        caloriesToTextField.inputAccessoryView = keyboardToolbar
        caloriesFromTextField.inputAccessoryView = keyboardToolbar
        ingredientsUpToTextField.inputAccessoryView = keyboardToolbar
    }
    
    private func createDietArray() -> Array<String> {
        filterArray.removeAll()
        for button in filtersButton {
            if button.isSelected {
                filterArray.append(DietFilters.allValue[button.tag].rawValue)
            }
        }
        return filterArray
    }
    
    private func createHealthArray() -> Array<String> {
        healthArray.removeAll()
        for button in healthButtons {
            if button.isSelected {
                healthArray.append(HealthFilters.allValue[button.tag].rawValue)
            }
        }
        return healthArray
    }
    
     func performItemCreation() -> FoodApiModel {
        item.q = searchTextField.text!
        item.diet = createDietArray()
        item.health = createHealthArray()
        item.caloriesFromInfo = Int(caloriesFromTextField.text!) ?? 0
        item.caloriesToInfo = Int(caloriesToTextField.text!) ?? 0
        item.ingredient = Int(ingredientsUpToTextField.text!) ?? 0
        item.calories.removeAll()
        if !((caloriesFromTextField.text?.isEmpty)! && (caloriesToTextField.text?.isEmpty)!){
            item.calories = createCaloriesString()
        }
        return item
    }
    
    private func createCaloriesString() -> String {
        var string = ""
        if (caloriesFromTextField.text?.isEmpty)! {
            string = String(format:"lte %@", caloriesToTextField.text!)
        } else if (caloriesToTextField.text?.isEmpty)! {
            string = String(format:"gte %@", caloriesFromTextField.text!)
        } else {
            string = String(format:"gte %@, lte %@", caloriesFromTextField.text!, caloriesToTextField.text!)
        }
        return string
    }

}

extension FiltersViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
   
        if searchTextField.isFirstResponder {
            textField.resignFirstResponder()
            router.feed.presentRecipesSearchListWithFilters(true, performItemCreation())
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
        
        if textField == ingredientsUpToTextField {
            let currentCharacterCount = textField.text?.characters.count ?? 0
            if (range.length + range.location > currentCharacterCount){
                return false
            }
            let newLength = currentCharacterCount + string.characters.count - range.length
            return newLength <= 2
        } else if textField == searchTextField {
            return true
        } else {
            let currentCharacterCount = textField.text?.characters.count ?? 0
            if (range.length + range.location > currentCharacterCount){
                return false
            }
            let newLength = currentCharacterCount + string.characters.count - range.length
            return newLength <= 6
        }
    }
}
