using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;


// NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "Service" in code, svc and config file together.
public class BankService : IBankService
{
    private Dictionary<string, AccountInfo> accounts = new Dictionary<string, AccountInfo>
        {
            { "ACC001", new AccountInfo { AccountNumber = "ACC001", AccountHolderName = "John Doe", Balance = 5000.00m, AccountType = "Savings" } },
            { "ACC002", new AccountInfo { AccountNumber = "ACC002", AccountHolderName = "Jane Smith", Balance = 10000.00m, AccountType = "Checking" } },
            { "ACC003", new AccountInfo { AccountNumber = "ACC003", AccountHolderName = "Bob Johnson", Balance = 2500.00m, AccountType = "Savings" } }
        };

    public decimal GetBalance(string accountNumber)
    {
        if (string.IsNullOrEmpty(accountNumber))
        {
            throw new ArgumentException("Account number cannot be null or empty.");
        }

        if (accounts.ContainsKey(accountNumber))
        {
            return accounts[accountNumber].Balance;
        }

        throw new InvalidOperationException("Account not found.");
    }

    public bool Deposit(string accountNumber, decimal amount)
    {
        if (string.IsNullOrEmpty(accountNumber))
        {
            throw new ArgumentException("Account number cannot be null or empty.");
        }

        if (amount <= 0)
        {
            throw new ArgumentException("Deposit amount must be greater than zero.");
        }

        if (accounts.ContainsKey(accountNumber))
        {
            accounts[accountNumber].Balance += amount;
            return true;
        }

        throw new InvalidOperationException("Account not found.");
    }

    public bool Withdraw(string accountNumber, decimal amount)
    {
        if (string.IsNullOrEmpty(accountNumber))
        {
            throw new ArgumentException("Account number cannot be null or empty.");
        }

        if (amount <= 0)
        {
            throw new ArgumentException("Withdrawal amount must be greater than zero.");
        }

        if (accounts.ContainsKey(accountNumber))
        {
            if (accounts[accountNumber].Balance >= amount)
            {
                accounts[accountNumber].Balance -= amount;
                return true;
            }
            else
            {
                throw new InvalidOperationException("Insufficient funds.");
            }
        }

        throw new InvalidOperationException("Account not found.");
    }

    public AccountInfo GetAccountInfo(string accountNumber)
    {
        if (string.IsNullOrEmpty(accountNumber))
        {
            throw new ArgumentException("Account number cannot be null or empty.");
        }

        if (accounts.ContainsKey(accountNumber))
        {
            return accounts[accountNumber];
        }

        throw new InvalidOperationException("Account not found.");
    }
}
