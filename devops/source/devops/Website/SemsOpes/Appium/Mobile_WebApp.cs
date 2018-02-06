using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using OpenQA.Selenium;
using OpenQA.Selenium.Appium;
using OpenQA.Selenium.Remote;
using System.Collections.Generic;
using System.Collections;
using OpenQA.Selenium.Appium.MultiTouch;
using OpenQA.Selenium.Appium.Interfaces;

using System.Threading;
using System.Drawing;
using OpenQA.Selenium.Interactions;
using Selendroid;

namespace Selendroid
{
    [TestClass]
    public class mobile_WebApp
    {
        private RemoteWebDriver driver;

        [TestInitialize]
        public void beforeAll()
        {
            DesiredCapabilities capabilities = new DesiredCapabilities();
            capabilities.SetCapability("platformName", "Android");
            capabilities.SetCapability("platformVersion", "4.2");
            capabilities.SetCapability("device", "Android");
            capabilities.SetCapability("browserName", "Chrome");
            //  capabilities.SetCapability("app", "Chrome");
            //  capabilities.SetCapability("app-package", "com.cit.myxpense");
            //capabilities.SetCapability("app-activity", "com.cit.myxpense.SplashActivity");
            // driver = new AppiumDriver(new Uri("http://127.0.0.1:4723/wd/hub"), capabilities);            
            driver = new RemoteWebDriver(new Uri("http://127.0.0.1:4723/wd/hub"), capabilities);
            // driver.Navigate().GoToUrl("Google.co.in");
            driver.Manage().Timeouts().ImplicitlyWait(TimeSpan.FromSeconds(60));
        }

        [TestMethod]
        public void TestMethod1()
        {
            driver.Navigate().GoToUrl("https://www.google.co.in");
            Thread.Sleep(1000);
            driver.FindElementByName("q").SendKeys("Appium");
            driver.FindElementByName("btnG").Click();
            Thread.Sleep(1000);
            driver.FindElementByPartialLinkText("Mobile App Automation Made Awesome").Click();
            Thread.Sleep(1000);
            Assert.AreEqual(driver.Title, "Appium: Mobile App Automation Made Awesome.");
        }

        [TestCleanup]
        public void afterAll()
        {
            driver.Quit();
        }
    }
}
