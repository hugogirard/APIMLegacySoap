using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;


// NOTE: You can use the "Rename" command on the "Refactor" menu to change the interface name "IService" in both code and config file together.
[ServiceContract]
public interface IBankService
{
    [OperationContract]
    decimal GetBalance(string accountNumber);

    [OperationContract]
    bool Deposit(string accountNumber, decimal amount);

    [OperationContract]
    bool Withdraw(string accountNumber, decimal amount);

    [OperationContract]
    AccountInfo GetAccountInfo(string accountNumber);
}

[DataContract]
public class AccountInfo
{
    [DataMember]
    public string AccountNumber { get; set; }

    [DataMember]
    public string AccountHolderName { get; set; }

    [DataMember]
    public decimal Balance { get; set; }

    [DataMember]
    public string AccountType { get; set; }
}


