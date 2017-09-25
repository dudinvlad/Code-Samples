//
//  NewRecipeViewController.swift
//  mymoodandme
//
//  Created by Alexander Bakuta on 23/08/2017.
//  Copyright © 2017 Inteza. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import NVActivityIndicatorView

class NewRecipeViewController: BaseController, NVActivityIndicatorViewable{

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    
    var dataSource: [Recipe] = [Recipe]()
    var uriArr: [RecipeURI] = [RecipeURI]()
    
    var viewModel = RecipesViewViewModel()
    var item = FoodApiModel()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        registrateCell()
        setupUI()
        tapForHideKeyboard()
        viewModel.modelMode = ModelMode.listRecipe
        setupData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.getFavoriteRecipes()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
        super.viewWillDisappear(true)
    }

    private func setupUI() {

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
        
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize.init(width: 0, height: 0)
        shadowView.layer.shadowOpacity = 0.6
        shadowView.layer.shadowRadius = 6.0
        
        searchView.layer.cornerRadius = 5
        searchView.layer.masksToBounds = true
        
        searchTextField.layer.masksToBounds = false
        searchTextField.layer.shadowColor = UIColor.black.cgColor
        searchTextField.layer.shadowOffset = CGSize.init(width: 0, height: 0)
        searchTextField.layer.shadowOpacity = 0.4
        searchTextField.layer.shadowRadius = 3.0
    }

    private func registrateCell() {
        collectionView.register(UINib.init(nibName: String(describing:RecipeCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: RecipeCollectionViewCell.self))
    }
    
    func setupData(){
        viewModel.recipes.asObservable().bind(onNext: {[unowned self] (recipes) in
            DispatchQueue.main.async {
                self.dataSource = []
                self.dataSource = recipes
                self.collectionView.reloadData()
            }
        }).addDisposableTo(disposeBag)
        
        viewModel.uri.asObservable().bind(onNext: {[unowned self] (uri) in
            DispatchQueue.main.async {
                self.uriArr = uri
                self.collectionView.reloadData()
            }
        }).addDisposableTo(disposeBag)
    }
    
    //MARK: - Action -
    
    @IBAction func searchButton(_ sender: Any) {
        view.endEditing(true)
        item.q = searchTextField.text!
        if !(searchTextField.text?.isEmpty)! {
            router.feed.presentRecipesSearchListWithFilters(true, item)
        }
    }
    
    @IBAction func favoriteAction(_ sender: UIBarButtonItem) {
        router.feed.presentFavoriteRecipes()
    }
    
    @IBAction func filtersAction(_ sender: UIButton) {
        router.feed.presentFilterScreen()
    }
}

extension NewRecipeViewController: UITextFieldDelegate {
    
    //MARK: - UITextFieldDelegate -
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
            item.q = searchTextField.text!
            if !(searchTextField.text?.isEmpty)! {
                router.feed.presentRecipesSearchListWithFilters(true, item)
            }
        }
        return true
    }
}

extension NewRecipeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout  {
    
    //MARK: - UICollectionViewDataSource -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: RecipeCollectionViewCell.self), for: indexPath) as? RecipeCollectionViewCell
            else {
                return UICollectionViewCell()
        }
        cell.delegate = self
        let data = dataSource[indexPath.item]
        for str in uriArr {
            if str.uri == data.indentification {
                cell.isFavorite = true
            } else {
                cell.isFavorite = false
            }
        }
        cell.recipe = Variable(data)
        
        return cell
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout -
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width/2.2, height: collectionView.frame.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var favorite = false
        let data = dataSource[indexPath.row]
        for str in uriArr {
            if str.uri  == data.indentification {
                favorite = true
            }
        }
        router.feed.presentDetailRecipe(true, data, favorite)
    }
    
    //MARK: - UICollectionViewDelegate -
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffSet = scrollView.contentOffset.x
        let maximumOffSet = scrollView.contentSize.width - scrollView.frame.size.width
        let deltaOffSet = maximumOffSet - currentOffSet
        if deltaOffSet <= 0 {
            viewModel.nextPageCall(withItem: item)
        }
    }
    

}

extension NewRecipeViewController: RecipeCollectionViewCellDelegate {
    
    //MARK: - RecipeCollectionViewCellDelegate -
    
    func addFavoriteRecipe(_ cell: RecipeCollectionViewCell) {
        let indexPath: IndexPath = collectionView.indexPath(for: cell)!
        let recipe:Recipe = dataSource[indexPath.row]
        viewModel.addFavoriteRecipe(recipe)
    }
    
    func deleteFavoriteRecipe(_ cell: RecipeCollectionViewCell) {
        let indexPath: IndexPath = collectionView.indexPath(for: cell)!
        let recipe:Recipe = dataSource[indexPath.row]
        let recipeURI = recipe.indentification
        
        for str in uriArr {
            if str.uri == recipeURI {
                let recipeID = String(str.id)
                viewModel.deleteFavorite(recipeID)
            }
        }
    }
}
