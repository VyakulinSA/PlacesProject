//
//  RaitingControl.swift
//  PlacesProject
//
//  Created by Вякулин Сергей on 16.09.2020.
//  Copyright © 2020 Вякулин Сергей. All rights reserved.
//

import UIKit

class RaitingControl: UIStackView {
    
    var raiting = 0.00 {// переменная для хранения рейтинга
        didSet{ //наблюдатель. При изменении значения рейтинга вызывает функция обновления состояния выделения кнопок
            updateButtonSelectionState()
        }
    }
    var update = true {
        didSet{ //наблюдатель. При изменении значения из вне, запускается настройка кнопок по новым параметрам
            setupButton()
        }
    }
    
    private var raitingButtons = [UIButton]() // создаем массив с кнопками для рейтинга
    
    var starsSize: CGSize = CGSize(width: 44.0, height: 44.0) {
        didSet{
            setupButton()
        }
    }
    var starCount: Int = 5
    
    

    override init(frame: CGRect) { //создаем инициализатор для работы с методом через код
        super.init(frame: frame)
        setupButton() //устанавливаем кнопку при инициализации StackView
    }
    
    //required означает, что супер класс требует обязательного использования данного иницализатора
    required init(coder: NSCoder) { //создаем инициализатор для работы через StoryBoard
        super.init(coder: coder)
        setupButton() //устанавливаем кнопку при инициализации StackView
    }
    
    
    @objc func raitingButtonTapped(button: UIButton) {
//        guard update == true else {return}
        guard let index = raitingButtons.firstIndex(of: button) else {return} //получаем индекс выбранного элемента из StackView
        
        
        let selectedRaiting = Double(index) + 1 //получаем выбранный рейтинг (+1 т.к. индексы идут с 0)
        
        if selectedRaiting == raiting { //если выбранный элемент равен предыдущему рейтингу, значит рейтинг ставим 0 и снимаем значение с кнопки
            raiting = 0.00
        }else {
            raiting = selectedRaiting //если не равен то присваиваем рейтинг и выбираем
        }
        
    }
    
    private func setupButton() { //прописываем метод создания кнопки
        
        //для того чтобы значения обновлялсь после изменений значений в StoryBoard необходимо написать дополнительный цикл удаления существующих элементов
        for button in raitingButtons {
            removeArrangedSubview(button) //удаляем кнопку из StackView
            button.removeFromSuperview() //удаляем кнопку
        }
        
        //по окончанию цикла мы очищаем массив кнопок
        raitingButtons.removeAll()
        
        //присваиваем переменным изображения кнопки в разных состояниях
        let bundle = Bundle(for: type(of: self)) //указываем с каким пакетом работаем (в данном случае пакет приложени собственного класса)
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection)
        let emptyStar = UIImage(named: "emptyStar", in: bundle, compatibleWith: self.traitCollection)
        let highlightedStar = UIImage(named: "highlightedStar", in: bundle, compatibleWith: self.traitCollection)
        
        for _ in 1...starCount{ //делаем цикл до 5 для создания 5 кнопок
            let button = UIButton() // объявляем кнопку
//            button.backgroundColor = .green //красим в красный
            
            //присваиваем изображения кнопкам при различных состояниях
            button.setImage(emptyStar, for: .normal)//для обычного состояния
            button.setImage(filledStar, for: .selected) // для выбранного
            button.setImage(highlightedStar, for: .highlighted) //для нажатого
            button.setImage(highlightedStar, for: [.highlighted, .selected]) //при повторном выборе
            
            
            //добавим програмно констрейнты для кнопки
            button.translatesAutoresizingMaskIntoConstraints = false //отключаем автоматически сгенерированные констрейнты элемента
            button.heightAnchor.constraint(equalToConstant: starsSize.height).isActive = true //привязываем констраинт высоты + включаем его (isActive)
            button.widthAnchor.constraint(equalToConstant: starsSize.width).isActive = true //ширины
            
            if update {
                button.addTarget(self, action: #selector(raitingButtonTapped(button:)), for: .touchUpInside) // добавляем действие для кнопки
                //self - означает что действие будет производиться из текущего класса
                //selector - само действие которое будет происходить
                //for - какое действие будет описано предыдущими параметрами (в нашем случае нажатие на кнопку)
            }


            addArrangedSubview(button) //добавляем кнопку в StackView (добавлено в массив представлений, упорядоченных стеком)
            
            raitingButtons.append(button) // добавляем в массив кнопки
        }
        updateButtonSelectionState()
        
    }
    
    private func updateButtonSelectionState () { //создаем метод для обновления наших кнопок в зависимости от выбранного индекса и рейтинга присвоенного кнопке
        for (index, button) in raitingButtons.enumerated(){ //перебираем словарь StackView с кнопками и получаем индексы
            button.isSelected = Double(index) < raiting //если индекс выбранной кнопки меньше рейтинга то выбираем все кнопки которые возвращают true
        }
    }
}
