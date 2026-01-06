# Brief Userguide for the BID3000 Exam Dashboard

This is the userguide for the BID3000 Exam PowerBI dashboard. Hopefully, the UI itself it pretty self explanatory. It consists of visuals in which you can drill directly into if there is support for it. You can also use the button slicers - single or multi select. 

## Participants

| Name | Student number | Student mail |
| --- | --- | --- |
| Jonas El Hbabi Helling | 263423 | 263423@usn.no |
| Kenneth Andreas Hansen | 209660 | 209660@usn.no |
| Lucas Leon Svaet Holter | 265954 | 265954@usn.no | 
| Kristian Martin Tvenning | 265931 | 265931@usn.no |

## Connection
The data is gathered from the `bid3000_eksamen` database. This database schema needs to be created manually in PostgreSQL. 

When the database is created, the `ETL_Jonas.py` Python file needs to be run to populate the tables with data. 

In theory, the `PowerBI.pbix` file should already have pointers to the database location, but if it does not...

Open the PowerBI desktop application. When having opened the `PowerBI.pbix` file, go to the `Home` tab in the Ribbon menu. 

Then, click on the `Get data` button. Click on `SQL Server`. In the `SQL Server database` window, enter `localhost` as the `Server`, and `bid3000_eksamen` as the `Database (optional)`. When being asked for encryption, click OK. 

Then, choose the database name (`bid3000_eksamen`) and click OK. 

Now it should load the tables, connections and field data into PowerBI. 

## Main Page

![Screenshot of the Main Page in PowerBI](../Dashboard/PowerBI_dashboard_Brief_Userguide_Screenshots/PowerBI_dashboard_Main_Page.png)

The main page gives an overview over operations. The top row consists of KPI cards for orientation. 

The next row shows Revenue by time dimensions, and is drillable from year to quarter by using the slicer buttons in the top row which drills every chart on the page accordingly. It also show buttons for page nagivation, which admittedly is a bit awkwardly placed due to the nature of the Sales vs Cancellations table, but is still presented clearly in an organized manner.

Then the third row shows Revenue by Country in logarithmic presentation, due to the variance making a linear presentation unfit for purpose. The row also shows a list of the top 5 selling products.

The fourth row shows a line chart of the cancellations trend, and a table of Sales vs Cancellations.

## Revenue

![Screenshot of the Revenue Page in PowerBI](../Dashboard/PowerBI_dashboard_Brief_Userguide_Screenshots/PowerBI_dashboard_Revenue.png/)

> __NOTE__: The `Revenue` page is "put on ice" for Main Page, Detailed Analysis Page and Customer segments.

__Total Revenue__  
Drillable bar chart to see revenue by `Year`, `Quarter`, `MonthName`. `DayOfMonth` and `Date`.

__Revenue Lost by Product__  
Donut chart of which products gives revenue loss.

__Average Order Value Trend__  
How much the average order is at what time. Drillable by `Year`, `Quarter`, `MonthName`. `DayOfMonth` and `Date`.

__Sum of Revenue by Customer__  
Which customers leave the most revenue.

__Revenue Lost to Cancellations by Country (log)__  
Bar chart visualization shown logarithmic sorted by revenue lost.

> Fun Fact: Did you know the `Maximum` value in the `Range` field in the `X-axis` dropdown menu in the `Visual` tab in the `Format Your Visual Tab` in the `Visualizations` pane is set to 01.01.1970, despite the line chart going to December 2011? This is because 01.01.1970 is _The Unix Epoch_ or [Unix time](https://en.wikipedia.org/wiki/Unix_time#cite_note-single-unix-spec-4.16-3).

## Cancellations
![Screenshot of the Cancellations Page in PowerBI](../Dashboard/PowerBI_dashboard_Brief_Userguide_Screenshots/PowerBI_Dashboard_Cancellations.png)
> __NOTE__: The `Cancellations` page is "put on ice" for Main Page, Detailed Analysis Page and Customer segments.

KPI cards showing Orders Cancelled in Total, Avg revenue pr cancelled order, Revenue Lost to Cancellations and Cancellation Rate % by Month. From the Overview page we can see that the Cancellation Rate % is only about 2%, but this gives £1.53M in revenue loss in only 2 years! So it is advisable to work on these. 

## Detailed Analysis Page

![Screenshot of the Detailed Analysis Page in PowerBI](../Dashboard/PowerBI_dashboard_Brief_Userguide_Screenshots/PowerBI_dashboard_Detailed_Analysis_Page.png)

The Detailed Analysis Page supports button slicing by `Year`, `Quarter`, `MonthName` and `countryname` for deeper insights into what markets one should put work towards. It also has nagivation buttons at the bottom navigating to the pages `Revenue`, `Cancellations` and `Customer Segments` in which the button is called `Business Insights and what to do...` because that page will show a more "layman friendly version" of advice, rather than hard facts of charts and bars. You can see much data in the other pages - but what do you _do_ with it? That is what this page says.

## Customer Segments

![Screenshot of Customer Segments Page in PowerBI](../Dashboard/PowerBI_dashboard_Brief_Userguide_Screenshots/PowerBI_Customer_Segments.png)

This is the page which presents the actionable business insights. The other pages mainly presents the data in form of visualizations. But what do you, as an employer, do with that data? You can act on it by intuition and previous experience, but you can also utilize mathematics to make those actions based on machine learning outcomes derived from the fact data. This page is what translates that data to textual actionable decisisions and what you delegate to your employees. 

Action Rank 1 is ommitted because it has `CustomerID` 0, which means unregistered customer.

The first table shows customer loyalty in 7 levels, the amount of customers in the customer loyalty segment, the monetary value of the segments, the frequency of orders all time, their cancel rate percentage, the cancelled revenue share percentage and segment advice.

Later, in the next table, this advice is also ranked in order of action rank which makes it easy for the sellers to know what to do. No decision fatigue here, simply pick up the phone and make the call, whether it be a hot or cold call.