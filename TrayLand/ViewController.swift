//
//  ViewController.swift
//  Postcards
//
//  Created by Chewy Wu on 8/10/18.
//  Copyright © 2018 Chewy Wu. All rights reserved.
//

import UIKit
import ARKit
@available(iOS 11.3, *)
class ViewController: UIViewController, ARSCNViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    let itemsArray_Image: [UIImage] = [#imageLiteral(resourceName: "bridge"), #imageLiteral(resourceName: "house"),#imageLiteral(resourceName: "tree"), #imageLiteral(resourceName: "mountain"),#imageLiteral(resourceName: "tower"), #imageLiteral(resourceName: "pole")]
    let itemsArray_Name: [String] = ["bridge","house","tree","mountain","tower","poles"]
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var btn_start: UIButton!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var text_loading: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    var selectedItem: String?
    var setLand = false
    var mainSceneNode = SCNNode()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        
        self.registerGestureRecognizers()
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        
        self.btn_start.alpha = 0
        self.btn_start.isEnabled = false
        self.btn_start.layer.cornerRadius = 10; // this value vary as per your desire

        itemsCollectionView.isHidden = true
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        
        if !hitTest.isEmpty {
            let results = hitTest.first!
            let node = results.node
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)

            if node.name != "landscape" {
                node.runAction(pinchAction)
                sender.scale = 1.0
            }
        }
        
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        if !setLand {
            setLand = true
        }
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)

        let hitTest = sceneView.hitTest(tapLocation, types:.existingPlaneUsingExtent)
        
        if !hitTest.isEmpty {
            self.addItem(hitTestResult: hitTest.first!)
        }
    }
    
    @objc func translate(sender: UIPanGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let location = sender.location(in: sceneView)
        let hitTestObject = sceneView.hitTest(location)
        let hitTest = sceneView.hitTest(location, types:.existingPlaneUsingExtent)
        
        if (!hitTest.isEmpty && !hitTestObject.isEmpty){
            let results = hitTestObject.first!
            let node = results.node

            let hitPlane = hitTest.first!
            let localTrans = hitPlane.localTransform.columns.3
        
            let newPosition = SCNVector3(localTrans.x, localTrans.y, localTrans.z)
            
            if node.name != "landscape" {
                node.position = newPosition
            }
        }
        
    }

    @objc func rotation(sender:  UIRotationGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let location = sender.location(in: sceneView)
        let hitTestObject = sceneView.hitTest(location)
        let rotation = Float(sender.rotation)
        
        if !hitTestObject.isEmpty {
            let results = hitTestObject.first!
            let node = results.node
           
            if node.name != "landscape" {
                if sender.state == .changed{
                    node.eulerAngles.y = node.eulerAngles.y - rotation * 0.04
                }
//                if(sender.state == .ended) {
//                    node.eulerAngles.y = node.eulerAngles.y
//               }
            }
        }
        
    }

    
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            let node = scene?.rootNode.childNode(withName: selectedItem, recursively: false)
            let localTrans = hitTestResult.localTransform.columns.3
            
            node?.position = SCNVector3(localTrans.x, localTrans.y, localTrans.z)
            
            self.mainSceneNode.addChildNode((node)!)
        }
    }
    
    func addSkyView() {
        let scene = SCNScene(named: "Models.scnassets/sunClouds.scn")
        let node = scene?.rootNode.childNode(withName: "sunClouds", recursively: false)
        
        node?.position = SCNVector3(0.3, 0.3, -0.1)
        let constraint = SCNLookAtConstraint(target: sceneView.pointOfView)
        constraint.isGimbalLockEnabled = true
        node?.constraints = [constraint]
        node?.name = "landscape"
        
        self.mainSceneNode.addChildNode((node)!)
    }
    
    func addPlane() {
        let scene = SCNScene(named: "Models.scnassets/delta_Plane.scn")
        let flightNode = scene?.rootNode.childNode(withName: "delta_Plane", recursively: false)
        flightNode?.position = SCNVector3(-0.15, 0.2, -0.1)
        flightNode?.eulerAngles = SCNVector3(0, -45.degreesToRadians, 0)
        
        let msgNode = SCNNode(geometry: SCNPlane(width: 3.8, height: 0.8))
        msgNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "message")
        msgNode.geometry?.firstMaterial?.isDoubleSided = true
        msgNode.pivot =  SCNMatrix4MakeTranslation(-2.2, 0, 0)
        msgNode.eulerAngles = SCNVector3(0, 75.degreesToRadians, 0)
        msgNode.position = SCNVector3(0, 0, 0)
        
        flightNode?.addChildNode(msgNode)
        flightNode?.name = "landscape"
        self.mainSceneNode.addChildNode((flightNode)!)
    }
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(translate))
        self.sceneView.addGestureRecognizer(panGesture)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotation))
        self.sceneView.addGestureRecognizer(rotateGesture)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray_Name.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! itemCell
        cell.itemImage.image = self.itemsArray_Image[indexPath.row]
        cell.layer.cornerRadius = 25;
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.selectedItem = self.itemsArray_Name[indexPath.row]
//        cell?.backgroundColor = UIColor.yellow
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func act_setLand(_ sender: Any) {
         self.setLand = true
         self.btn_start.isHidden = true
         self.itemsCollectionView.isHidden = false
         self.text_loading.isHidden = true
        
        self.addSkyView()
        self.addPlane()
        
        self.sceneView.debugOptions = []
        self.configuration.planeDetection = []
        self.sceneView.session.run(configuration)
        
    }
    

    func createLand(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(CGFloat(planeAnchor.extent.z))))
        let planeColor = UIColor(red: 168, green: 152, blue: 136)
        planeNode.geometry?.firstMaterial?.diffuse.contents = planeColor
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        planeNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        
        
//        let scene = SCNScene(named: "Models.scnassets/landscape2.scn")
//        let node = scene?.rootNode.childNode(withName: "landscape", recursively: false)
//        node?.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
//        node?.scale = SCNVector3(CGFloat(planeAnchor.extent.x), 0.3, CGFloat(planeAnchor.extent.z))
        planeNode.name = "landscape"
        
        return planeNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if(!self.setLand){
            guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
            let landNode = createLand(planeAnchor: planeAnchor)
            node.addChildNode(landNode)
           
            DispatchQueue.main.async {
                self.btn_start.isEnabled = true
                self.btn_start.alpha = 1;
                self.text_loading.text = "found land"
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
         if (!self.setLand){
            guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
            node.enumerateChildNodes { (childNode, _) in
                childNode.removeFromParentNode()
            }
            let landNode = createLand(planeAnchor: planeAnchor)
            node.addChildNode(landNode)
            DispatchQueue.main.async {
               self.text_loading.text = "increasing land size..."
            }
            
         } else {
            node.addChildNode(self.mainSceneNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()

        }
    }

}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

