using System;
using System.Collections;
using System.Threading;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using OpenQA.Selenium;
using OpenQA.Selenium.Remote;
using OpenQA.Selenium.Support.UI;


namespace Selendroid
{
    [TestClass]
    public class mobile_HybridApp
    {
        private RemoteWebDriver driver;

        [TestInitialize]
        public void beforeAll()
        {
            DesiredCapabilities dc = new DesiredCapabilities();
            dc.SetCapability("platformName", "Android");
            dc.SetCapability("platformVersion", "4.2");
            dc.SetCapability("device", "Android Emulator");
            dc.SetCapability("app", "D:\\Vallinayaki-Data\\Valli\\Valli-Others\\Androidproject\\MMMCloudLibrary-release.apk");
            dc.SetCapability("app-package", "com.mmm.android.cloudlibrary");
            dc.SetCapability("app-activity", "com.mmm.android.cloudlibrary.ui.SplashActivity");
            driver = new RemoteWebDriver(new Uri("http://127.0.0.1:4723/wd/hub"), dc);

        }

        [TestMethod]
        public void cloudAppTest()
        {
            // package name : com.txtr.android.mmm  com.mmm.android.cloudlibrary
            // activity name : ui.intro.MmmIntroActivity  'com.mmm.android.cloudlibrary.ui.SplashActivity'

            driver.FindElementByName("QA").Click();
            driver.FindElementByClassName("android.widget.TextView").Click();
            var dw = new WebDriverWait(driver, new TimeSpan(0, 0, 120));
            dw.Until(drv => drv.FindElement(By.Name("Alaska")));
            //Thread.Sleep(5000);            
            driver.FindElement(By.Name("Alaska")).Click();
            Thread.Sleep(10000);
            IJavaScriptExecutor js = (IJavaScriptExecutor)driver;
            Hashtable ht = new Hashtable();
            ht.Add("endX", 0);
            ht.Add("endY", 0);
            ht.Add("touchCount", 1);
            js.ExecuteScript("mobile: flick", ht);
            IJavaScriptExecutor js1 = (IJavaScriptExecutor)driver;
            Hashtable ht1 = new Hashtable();
            ht1.Add("endX", 0);
            ht1.Add("endY", 0);
            ht1.Add("touchCount", 1);
            js1.ExecuteScript("mobile: flick", ht);
            driver.FindElementByName("CongruentTest").Click();
            //var dw1 = new WebDriverWait(driver, new TimeSpan(0, 0, 120));
            dw.Until(drv => drv.FindElement(By.ClassName("android.widget.EditText")));
            driver.FindElementByClassName("android.widget.EditText").SendKeys("bala11");
            driver.FindElementByClassName("android.widget.Button").Click();
            dw.Until(drv => drv.FindElement(By.Name("Accept")));
            driver.FindElement(By.Name("Accept")).Click();
            driver.FindElement(By.ClassName("android.widget.ImageView")).Click();
            Thread.Sleep(15000);
            driver.FindElement(By.Name("Settings")).Click();
            driver.FindElementByClassName("android.widget.Button").Click();
            Thread.Sleep(15000);
            driver.FindElementByName("Logout").Click();
        }

        [TestCleanup]
        public void afterAll()
        {
            driver.Quit();
        }
    }
}
