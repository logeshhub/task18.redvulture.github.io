using OpenQA.Selenium;
using OpenQA.Selenium.Appium;
using OpenQA.Selenium.Remote;
using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Collections.Generic;
using System.Collections;
using OpenQA.Selenium.Appium.MultiTouch;
using OpenQA.Selenium.Appium.Interfaces;
using System.Threading;
using System.Drawing;
using OpenQA.Selenium.Interactions;
using Selendroid;




namespace AppiumDriverDemo
{
    [TestClass]

    public class ProgramTest
    {
        // private AppiumDriver driver;
        private RemoteWebDriver driver;

        [TestInitialize]
        public void beforeAll()
        {
            DesiredCapabilities capabilities = new DesiredCapabilities();
            capabilities.SetCapability("platformName", "Android");
            capabilities.SetCapability("platformVersion", "4.2");
            capabilities.SetCapability("device", "Android Emulator");
            capabilities.SetCapability("app", "D:\\Vallinayaki-Data\\Valli\\Valli-Others\\Androidproject\\MyXpense.apk");
            capabilities.SetCapability("app-package", "com.cit.myxpense");
            capabilities.SetCapability("app-activity", "com.cit.myxpense.SplashActivity");
            // driver = new AppiumDriver(new Uri("http://127.0.0.1:4723/wd/hub"), capabilities);            
            driver = new RemoteWebDriver(new Uri("http://127.0.0.1:4723/wd/hub"), capabilities);
        }

        [TestCleanup]
        public void afterAll()
        {
            // shutdown
            driver.Quit();
        }

        [TestMethod]
        public void AppiumDriverMethodsTestCase()
        {
            // Using appium extension methods
            //AppiumWebElement 
            driver.Manage().Timeouts().ImplicitlyWait(TimeSpan.FromSeconds(60));
            driver.FindElementByName("Select").Click();

            IJavaScriptExecutor js = (IJavaScriptExecutor)driver;
            Hashtable map = new Hashtable();
            /* map.Add("touchCount", 1);
             map.Add("startX", 24);
             map.Add("startY", 559);
             map.Add("endX", 30);
             map.Add("endY", 507);
             map.Add("duration", 50);            

             js.ExecuteScript("mobile: swipe", map);     */

            // map.Add("element", element);
            //  js.ExecuteScript("mobile: scrollTo", map);
            //driver.FindElementByName("India").Click();       

            //int count =  driver.FindElements(By.Name("India")).Count;

            for (int i = 0; i < 15; i++)
            {
                if (!isElementPresent(driver))
                {
                    IJavaScriptExecutor js1 = (IJavaScriptExecutor)driver;
                    Hashtable flickObject = new Hashtable();
                    flickObject.Add("endX", 0);
                    flickObject.Add("endY", 0);
                    flickObject.Add("touchCount", 1);
                    js1.ExecuteScript("mobile: flick", flickObject);
                }
                else
                {
                    break;
                }
                continue;
            }
            driver.FindElementByName("India").Click();
            driver.FindElementByName("Next").Click();
            //driver.FindElementByXPath("//relativeLayout/editText[1]").SendKeys("a");
            //driver.FindElementByXPath("//relativeLayout/editText[3]").SendKeys("a");
            // driver.FindElementByName("password").SendKeys("a");
            driver.FindElementByName("Skip").Click();
            driver.FindElementByName("Skip").Click();
            driver.FindElementByName("Skip").Click();
            driver.Manage().Timeouts().ImplicitlyWait(TimeSpan.FromSeconds(60));
            driver.FindElementByName("Add Income").Click();
            driver.Manage().Timeouts().ImplicitlyWait(TimeSpan.FromSeconds(60));
            driver.FindElementByName("Rent Income").Click();
            driver.FindElementByClassName("android.widget.Button").Click();
            //driver.FindElement(By.XPath("//EditText[contains(@text,'description')]"));
            //driver.FindElement(By.TagName("EditText")).SendKeys("Test");
            //driver.FindElement(By.XPath("//relativeLayout/editText[7]")).SendKeys("10500.00");
            //driver.FindElement(By.XPath("//frameLayout[0]/relativeLayout/editText[7]")).Click();
        }

        public bool isElementPresent(IWebDriver webdriver)
        {
            bool exists = false;

            webdriver.Manage().Timeouts().ImplicitlyWait(TimeSpan.FromMilliseconds(60));

            try
            {
                exists = driver.FindElementByName("India").Displayed;
                exists = true;
            }
            catch (NoSuchElementException e)
            {
                // nothing to do.
            }

            webdriver.Manage().Timeouts().ImplicitlyWait(TimeSpan.FromMilliseconds(60));

            return exists;
        }
    }

}