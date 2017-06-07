

import UIKit
import PassKit

class ViewController: UIViewController {

    @IBOutlet weak var applePayLabel: UILabel!
    
    // For Apple pay
    fileprivate var tn: String!
    // "00" for distrubution, "01" for testing
    // TODO: replace [mode]
    fileprivate let mode = "01"
    // TODO: replace []
    fileprivate let merchantID = "your merchant id"

    fileprivate var payNetworks = [PKPaymentNetwork]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isApplePayAvailable() {
            applePayLabel.text = "支持 Apple Pay"
            let payItem = PKPaymentButton(type: .plain, style: .black)
            payItem.center = view.center
            payItem.addTarget(self, action: #selector(applePay), for: .touchUpInside)
            view.addSubview(payItem)
        } else {
            applePayLabel.text = "不支持 Apple Pay"
        }
    }
}


// MARK: - Apple Pay

extension ViewController: UPAPayPluginDelegate {
    
    // MARK: UPAPay Delegate
    func upaPayPluginResult(_ payResult: UPPayResult!) {
        if let status = payResult?.paymentResultStatus {
            switch status {
            case .success:
                print("success")
                let otherInfo = payResult.otherInfo ?? ""
                let successInfo = "支付成功\n\(otherInfo)"
                showAlert(successInfo)
            case .failure:
                print("failure")
                let errorInfo = payResult.errorDescription ?? "支付失败"
                showAlert(errorInfo)
            case .cancel:
                print("cancel")
                showAlert("支付取消")
            case .unknownCancel:
                print("unknownCancel")
                let errorInfo = ""
                // TODO: get [errorInfo] from server, may success or failure
                showAlert(errorInfo)
            }
        }
    }
    
    // MARK: - Helper
    
    fileprivate func isApplePayAvailable() -> Bool {
        var available = false
        
        // 需要银联
        if #available(iOS 9.2, *) {
            if PKPaymentAuthorizationViewController.canMakePayments() {
                payNetworks = [.chinaUnionPay]
                available = true
            }
        } else {
            // Fallback on earlier versions
        }
        
        return available
    }
    
    
    @objc fileprivate func applePay() {
        // Check whether the network is support
        if !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: payNetworks) {
            let msg = "当前设备没有包含支持的支付银联卡, 你可以到 Wallet 应用添加银联卡"
            showAlert(msg)
            return
        }
        
        // Get TN
        fetchTransactionNumber { [weak self] tnResult in
            if tnResult != nil {
                self?.tn = tnResult
                self?.tnPay()
            }
        }
    }
    
    private func tnPay() {
        if tn != nil && tn.characters.count > 0 {
            UPAPayPlugin.startPay(tn,
                                  mode: mode,
                                  viewController: self,
                                  delegate: self,
                                  andAPMechantID: merchantID)
        } else {
            showAlert("获得交易单号失败")
        }
    }
    
    private func fetchTransactionNumber(callbacK: @escaping (_ tn: String?) -> ()) {
        // TODO: replace ["http://101.231.204.84:8091/sim/getacptn"]
        let urlString = "http://101.231.204.84:8091/sim/getacptn"
        
        // 处理的很粗糙
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error == nil {
                    if let data = data {
                        if let tnString = String(data: data, encoding: String.Encoding.utf8) {
                            print("tn String = \(tnString)")
                            callbacK(tnString)
                        }
                    }
                }
            })
            task.resume()
        }
    }
    
    private func showAlert(_ info: String) {
        let alert = UIAlertController(title: "提示", message: info, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}


