//+------------------------------------------------------------------+
//|                                                  tick-notify.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <socket-library-mt4-mt5.mqh>

//--- input parameters
int initKline = 1000;
input string   gHost = "127.0.0.1";
input ushort   gPort = 8000;

ClientSocket * glbClientSocket = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   int count = 0;
   while(count <= 3)
   {
      if (glbClientSocket && glbClientSocket.IsSocketConnected())
         break;
         
      if (glbClientSocket) 
      {
         delete glbClientSocket;
         glbClientSocket = NULL;
      }
         
      if(!glbClientSocket)
      {
         glbClientSocket = new ClientSocket(gHost, gPort);
         if (glbClientSocket.IsSocketConnected()) 
         {
            Print("Client connection succeeded");
         } 
         else 
         {
            Print("Client connection failed");
         }
      }
      
      ++count;
   }
   
   if(!glbClientSocket || !glbClientSocket.IsSocketConnected())
   {
      return INIT_FAILED;
   }
   
   int total = Bars;
   if(Bars > 1000)
      
   
   
   //上报历史数据
   for(int i = 0; i < initKline; ++i)
   {
      if(i >= Bars)
         break;
      string buff = getBarsInfo(i);
      glbClientSocket.Send(buff);
   }   
   Print("init finish");
   
   return(INIT_SUCCEEDED);
}
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if (glbClientSocket) 
   {
      delete glbClientSocket;
      glbClientSocket = NULL;
   }
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if (!glbClientSocket) 
   {
      glbClientSocket = new ClientSocket(gHost, gPort);
      if (glbClientSocket.IsSocketConnected()) 
      {
         Print("Client connection succeeded");
      } 
      else 
      {
         Print("Client connection failed");
      }
   }
   
   if (glbClientSocket.IsSocketConnected()) 
   {
      // Send the current price as a CRLF-terminated message
      string strMsg = getTickInfo();
      glbClientSocket.Send(strMsg); 
      
      if (initKline < Bars) 
      {
         strMsg = getBarsInfo(initKline);
         glbClientSocket.Send(strMsg);
         ++initKline;
      }  
   } 
   else 
   {
      // Either the connection above failed, or the socket has been closed since an earlier
      // connection. We handle this in the next block of code...
   }
   
   // If the socket is closed, destroy it, and attempt a new connection
   // on the next call to OnTick()
   if (!glbClientSocket.IsSocketConnected()) 
   {
      // Destroy the server socket. A new connection
      // will be attempted on the next tick
      Print("Client disconnected. Will retry.");
      delete glbClientSocket;
      glbClientSocket = NULL;
   }
}

//当前的tick信息
string getTickInfo()
{
   string strName = Symbol() + "-" + IntegerToString(Period());
   string strTimestamp = IntegerToString(TimeGMT());
   string strTime = IntegerToString(Time[0]);
   string strBid = DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_BID), 6);
   string strAsk = DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_ASK), 6);
   string strOpen =  DoubleToString(Open[0]);
   string strClose =  DoubleToString(Close[0]);
   string strHigh =  DoubleToString(High[0]);
   string strLow =  DoubleToString(Low[0]);
      
   string strMsg = "t:" + strName + "|" + strTimestamp + "|" + strTime + "|" + strBid + "|"
                     + strAsk + "|" + strOpen + "|" + strClose + "|" + strHigh + "|" + strLow + "\n"; 
                     
   return strMsg;
}

//获取k线柱的信息
string getBarsInfo(int index)
{   
   string strName = Symbol() + "-" + IntegerToString(Period());
   string strIndex = IntegerToString(index);
   string strTime = IntegerToString(Time[index]);
   string strOpen =  DoubleToString(Open[index]);
   string strClose =  DoubleToString(Close[index]);
   string strHigh =  DoubleToString(High[index]);
   string strLow =  DoubleToString(Low[index]);
      
   string strMsg = "k:" + strName + "|" + strIndex  + "|" + strTime + "|" + strOpen 
                     + "|" + strClose + "|" + strHigh + "|" + strLow + "\n"; 
                     
   return strMsg;
}
