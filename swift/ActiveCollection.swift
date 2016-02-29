//
//  ActiveCollection.swift
//  SplitGreens
//
//  Created by Oleksii Pylko on 23/02/16.
//  Copyright © 2016 Oleksii Pylko. All rights reserved.
//

import Foundation
import RealmSwift

class ActiveCollection<T: Object where T: ActiveRecordProtocol> : ActiveCollectionProtocol {
    
    lazy var realm = try! Realm()
    
    lazy var collection:Results<T> = self.fetchCollection()
    
    func fetchCollection() -> Results<T> {
        return self.realm.objects(T).sorted("date", ascending: false)
    }
    
    func add(model: ActiveModelProtocol) {
        try! realm.write {
            let record = T.constructWithActiveModel(model)
            self.realm.add(record as! Object, update: true)
        }
    }
    
    func removeAtIndex(index: Int) {
        try! realm.write {
            self.realm.delete(collection[index])
        }
    }
    
    var count:Int {
        return collection.count
    }
    
    subscript(index: Int) -> ActiveModelProtocol? {
        return collection[index].toActiveModel()
    }
    
}
