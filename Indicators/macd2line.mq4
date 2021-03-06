//+------------------------------------------------------------------+
//|                                                 macd_hull_ma.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <MovingAverages.mqh>

#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_level1  0
#property indicator_buffers 3
#property indicator_plots   3
//--- plot fastLine
#property indicator_label1  "fastLine"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrNavy
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot slowLine
#property indicator_label2  "slowLine"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot macd
#property indicator_label3  "macd"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input int                fastPeriod   = 5;          // Fast Hull period
input int                slowPeriod   = 17;          // Slow Hull period
input int                signalPeriod = 3;           // Signal period
input ENUM_APPLIED_PRICE inputPrice        = PRICE_CLOSE; // Price 
//--- indicator buffers
double         fastBuffer[];
double         slowBuffer[];
double         macdBuffer[];
int lastTotal=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,fastBuffer);
   SetIndexBuffer(1,slowBuffer);
   SetIndexBuffer(2,macdBuffer);

   IndicatorShortName("MACD2Line("+IntegerToString(fastPeriod)+","+IntegerToString(slowPeriod)+","+IntegerToString(signalPeriod)+")");
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   // Print("fastBuffer[0]="+fastBuffer[0]+"slowBuffer[0]="+slowBuffer[0]);
   if(rates_total<slowPeriod || rates_total<fastPeriod)
     {
      return(0);
     }
   int i,limit;
   if(lastTotal==rates_total)
     {
      return(rates_total);
     }
   if(lastTotal==0)
     {
      lastTotal=rates_total;
      limit=rates_total;
     }
   else if(rates_total > lastTotal)
      {
       limit=rates_total-lastTotal;
       lastTotal=rates_total;
      }
   if(prev_calculated>0)
      limit++;
   Print("lastTotal="+lastTotal+",rates_total="+rates_total+",prev_calculated="+prev_calculated+",limit="+limit);
   for(i=0; i<limit; i++)
     {      
      fastBuffer[i]=iMA(NULL,0,fastPeriod,0,MODE_EMA,inputPrice,i)-iMA(NULL,0,slowPeriod,0,MODE_EMA,inputPrice,i);
     }
   for(i=0; i<limit; i++)
     {      
      slowBuffer[i]=iMAOnArray(fastBuffer,ArraySize(fastBuffer),signalPeriod,0,MODE_EMA,i);
     }
   for(i=0;i<limit;i++)
     {
      macdBuffer[i]=fastBuffer[i]-slowBuffer[i];
     }
   
   return(rates_total);
  }



#define _hullInstances 2
#define _hullInstancesSize 2
double workHull[][_hullInstances*_hullInstancesSize];
//
//---
//
double iHull(double price,double period,int r,int bars,int instanceNo=0)
  {
   if(ArrayRange(workHull,0)!=bars) ArrayResize(workHull,bars);
   instanceNo*=_hullInstancesSize; workHull[r][instanceNo]=price;
   if(period<=1) return(price);
//
//---
//
   int HmaPeriod  = (int)MathMax(period,2);
   int HalfPeriod = (int)MathFloor(HmaPeriod/2);
   int HullPeriod = (int)MathFloor(MathSqrt(HmaPeriod));
   double hma,hmw,weight;
   hmw=HalfPeriod; hma=hmw*price;
   for(int k=1; k<HalfPeriod && (r-k)>=0; k++)
     {
      weight = HalfPeriod-k;
      hmw   += weight;
      hma   += weight*workHull[r-k][instanceNo];
     }
   workHull[r][instanceNo+1]=2.0*hma/hmw;
   hmw=HmaPeriod; hma=hmw*price;
   for(int k=1; k<period && (r-k)>=0; k++)
     {
      weight = HmaPeriod-k;
      hmw   += weight;
      hma   += weight*workHull[r-k][instanceNo];
     }
   workHull[r][instanceNo+1]-=hma/hmw;
   hmw=HullPeriod; hma=hmw*workHull[r][instanceNo+1];
   for(int k=1; k<HullPeriod && (r-k)>=0; k++)
     {
      weight = HullPeriod-k;
      hmw   += weight;
      hma   += weight*workHull[r-k][1+instanceNo];
     }
   return(hma/hmw);
  }
//
//---
//
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   if(i>=0)
      switch(tprice)
        {
         case PRICE_CLOSE:     return(close[i]);
         case PRICE_OPEN:      return(open[i]);
         case PRICE_HIGH:      return(high[i]);
         case PRICE_LOW:       return(low[i]);
         case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
         case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
         case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
        }
   return(0);
  }
