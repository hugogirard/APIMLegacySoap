using System;
using SoapClient.Bank;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("===========================================");
        Console.WriteLine("   Welcome to the Banking System Client   ");
        Console.WriteLine("===========================================");
        Console.WriteLine();

        string endpointConfigurationName = "BasicHttpsBinding_IBankService";
        string endpointRemoteAddress = "https://soap-api-beaxsegxu6fsi.azurewebsites.net/Service.svc";
        
        using (var client = new BankServiceClient(endpointConfigurationName, endpointRemoteAddress))
        {
            bool exit = false;

            while (!exit)
            {
                try
                {
                    Console.WriteLine("\nPlease select an option:");
                    Console.WriteLine("1. Check Balance");
                    Console.WriteLine("2. Deposit Money");
                    Console.WriteLine("3. Withdraw Money");
                    Console.WriteLine("4. View Account Information");
                    Console.WriteLine("5. Exit");
                    Console.Write("\nEnter your choice (1-5): ");

                    string choice = Console.ReadLine();

                    switch (choice)
                    {
                        case "1":
                            CheckBalance(client);
                            break;
                        case "2":
                            DepositMoney(client);
                            break;
                        case "3":
                            WithdrawMoney(client);
                            break;
                        case "4":
                            ViewAccountInfo(client);
                            break;
                        case "5":
                            exit = true;
                            Console.WriteLine("\nThank you for using our Banking System. Goodbye!");
                            break;
                        default:
                            Console.WriteLine("\nInvalid choice. Please try again.");
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"\nError: {ex.Message}");
                }
            }
        }

        Console.WriteLine("\nPress any key to exit...");
        Console.ReadKey();
    }

    static void CheckBalance(BankServiceClient client)
    {
        Console.Write("\nEnter Account Number: ");
        string accountNumber = Console.ReadLine();

        try
        {
            decimal balance = client.GetBalance(accountNumber);
            Console.WriteLine($"\nCurrent Balance: ${balance:N2}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"\nFailed to retrieve balance: {ex.Message}");
        }
    }

    static void DepositMoney(BankServiceClient client)
    {
        Console.Write("\nEnter Account Number: ");
        string accountNumber = Console.ReadLine();

        Console.Write("Enter Deposit Amount: $");
        string amountInput = Console.ReadLine();

        if (decimal.TryParse(amountInput, out decimal amount))
        {
            try
            {
                bool success = client.Deposit(accountNumber, amount);
                if (success)
                {
                    Console.WriteLine($"\nDeposit successful! ${amount:N2} has been added to your account.");
                    decimal newBalance = client.GetBalance(accountNumber);
                    Console.WriteLine($"New Balance: ${newBalance:N2}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\nDeposit failed: {ex.Message}");
            }
        }
        else
        {
            Console.WriteLine("\nInvalid amount entered.");
        }
    }

    static void WithdrawMoney(BankServiceClient client)
    {
        Console.Write("\nEnter Account Number: ");
        string accountNumber = Console.ReadLine();

        Console.Write("Enter Withdrawal Amount: $");
        string amountInput = Console.ReadLine();

        if (decimal.TryParse(amountInput, out decimal amount))
        {
            try
            {
                bool success = client.Withdraw(accountNumber, amount);
                if (success)
                {
                    Console.WriteLine($"\nWithdrawal successful! ${amount:N2} has been deducted from your account.");
                    decimal newBalance = client.GetBalance(accountNumber);
                    Console.WriteLine($"New Balance: ${newBalance:N2}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\nWithdrawal failed: {ex.Message}");
            }
        }
        else
        {
            Console.WriteLine("\nInvalid amount entered.");
        }
    }

    static void ViewAccountInfo(BankServiceClient client)
    {
        Console.Write("\nEnter Account Number: ");
        string accountNumber = Console.ReadLine();

        try
        {
            AccountInfo accountInfo = client.GetAccountInfo(accountNumber);

            Console.WriteLine("\n===========================================");
            Console.WriteLine("          Account Information");
            Console.WriteLine("===========================================");
            Console.WriteLine($"Account Number:    {accountInfo.AccountNumber}");
            Console.WriteLine($"Account Holder:    {accountInfo.AccountHolderName}");
            Console.WriteLine($"Account Type:      {accountInfo.AccountType}");
            Console.WriteLine($"Current Balance:   ${accountInfo.Balance:N2}");
            Console.WriteLine("===========================================");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"\nFailed to retrieve account information: {ex.Message}");
        }
    }
}
