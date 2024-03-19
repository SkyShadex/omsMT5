//+------------------------------------------------------------------+
//|                                                         SkyBot_2 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#define        GV_PREVDATE "PreviousDate"

sinput group "Network Configuration"
sinput bool           clientside_sell = false; //Sell orders handled locally. Exclusively
sinput bool           clientside_sellOrders = false;
sinput bool           clientside_freeup_order = false; //will cancel old orders before placing new one. If using pyramid orders or price lag this is useful.
sinput string         Address = "localhost";
sinput int            Port = 5000;
bool           ExtTLS =false;
uint           lastErrorTime = 0;
int            Eventtimer = 1;

//+------------------------------------------------------------------+
//| Send command to the server                                       |
//+------------------------------------------------------------------+
bool HTTPSend(int socket,string request)
  {
   char req[];
   int  len=StringToCharArray(request,req)-1;
   if(len<0)
      return(false);
//--- if secure TLS connection is used via the port 443
   if(ExtTLS)
      return(SocketTlsSend(socket,req,len)==len);
//--- if standard TCP connection is used
   return(SocketSend(socket,req,len)==len);
  }
//+------------------------------------------------------------------+
//| Read server response                                             |
//+------------------------------------------------------------------+
string responseHTTP;
bool HTTPRecv(int socket,uint timeout)
  {
   char   rsp[];
   string result;
   uint   timeout_check=GetTickCount()+timeout;
//--- read data from sockets till they are still present but not longer than timeout
   do
     {
      uint len=SocketIsReadable(socket);
      if(len)
        {
         int rsp_len;
         //--- various reading commands depending on whether the connection is secure or not
         if(ExtTLS)
            rsp_len=SocketTlsRead(socket,rsp,len);
         else
            rsp_len=SocketRead(socket,rsp,len,timeout);
         //--- analyze the response
         if(rsp_len>0)
           {
            result+=CharArrayToString(rsp,0,rsp_len);
            //--- print only the response header
            int header_end=StringFind(result,"\r\n\r\n");
            if(header_end>0)
              {
               //Print("HTTP answer header received:");
               //Print(StringSubstr(result,0,header_end));
               string data = StringSubstr(result, header_end);
               if(StringLen(data)>10)
                 {
                  responseHTTP = StringSubstr(result, header_end);
                  return(true);
                 }
              }
           }
        }
     }
   while(GetTickCount()<timeout_check && !IsStopped());
   string error ="";
   if(GetTickCount() - lastErrorTime > 5 * 1000)  // Rate-limit retries to once every 5 seconds
     {
      lastErrorTime = GetTickCount();
      error = "Error occurred while reading server response";
      Print(error);
     }
   return(false);
  }


//+------------------------------------------------------------------+
//|          Handle Socket                                           |
//+------------------------------------------------------------------+
void socketSystem(bool control)
  {
   if(!control)
      return;

   int socket = SocketCreate();
   if(socket == INVALID_HANDLE)
     {
      Print("Failed to create a socket, error ", GetLastError());
      return;
     }

// Connect to the server
   if(!SocketConnect(socket, Address, Port,1000))
     {
      Print(Address, ":", Port, " Connection failed. Error ", GetLastError());
      SocketClose(socket); // Close the socket in case of a connection failure
      lastErrorTime++;
      return;
     }

// Send GET request to the server
   if(!HTTPSend(socket, "GET /mt5client HTTP/1.1\r\nHost: localhost:5000\r\nUser-Agent: MT5\r\n\r\n"))
     {
      // Read the response
      //string response = HTTPRecv(socket, 1000);
      Print("Failed to send GET request, error ", GetLastError());
      SocketClose(socket);
      return;
     }

   if(!HTTPRecv(socket,5000))
     {
      Print("Failed to get a response, error ",GetLastError());
      SocketClose(socket);
      return;
     }

// Response received, process the data
   ParsePayload tradeData(responseHTTP);
   if(StringLen(tradeData.GetSymbol())>0)
      IsValidOrder(tradeData);
   lastErrorTime = 0;
   SocketClose(socket);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DDoSProtect()
  {
   if(lastErrorTime>10)
     {
      int i = 60;
      lastErrorTime = 5;
      EventKillTimer();
      Eventtimer+=5;
      if(Eventtimer>i)
         Eventtimer=i;
      EventSetTimer(Eventtimer);
      Print(__FUNCTION__," ",Eventtimer," ",lastErrorTime);
     }
   else
      if(lastErrorTime == 0 && Eventtimer > 1)
        {
         Eventtimer-=30;
        }
      else
        {
         Eventtimer = 1;
        }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void noDebugOrders()
  {
   if(GlobalVariableCheck(GV_PREVDATE))
     {
      previousDateTime = GlobalVariableGet(GV_PREVDATE);
     }

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ParsePayload
  {
private:
   datetime          timestamp;
   string            symbol;
   string            side;
   double            price;
   double            quantity;
   string            comment;
   string            orderID;

public:
                     ParsePayload(string payload)
     {
      int timestampIndex = StringFind(payload, "Timestamp:");
      int commaIndex = StringFind(payload, ",", timestampIndex);
      string timestampStr = StringSubstr(payload, timestampIndex + 11, commaIndex - timestampIndex - 11);
      timestamp = StringToDouble(timestampStr);

      if(timestamp < 1)
         return;

      int symbolIndex = StringFind(payload, "Symbol:");
      int sideIndex = StringFind(payload, "Side:", symbolIndex);
      symbol = StringSubstr(payload, symbolIndex + 8, sideIndex - symbolIndex - 8);

      int priceIndex = StringFind(payload, "Price:");
      int quantityIndex = StringFind(payload, "Quantity:", priceIndex);
      side = StringSubstr(payload, sideIndex + 5, priceIndex - sideIndex - 5);

      string priceStr = StringSubstr(payload, priceIndex + 6, quantityIndex - priceIndex - 6);
      price = StringToDouble(priceStr);

      int commentIndex = StringFind(payload, "Comment:");
      string quantityStr = StringSubstr(payload, quantityIndex + 10, commentIndex - quantityIndex - 10);
      quantity = StringToDouble(quantityStr);


      int orderIDIndex = StringFind(payload, "Order ID:", commentIndex);
      comment = StringSubstr(payload, commentIndex + 9, orderIDIndex - commentIndex - 9);
      orderID = StringSubstr(payload, orderIDIndex + 9);
     }

   // Define getter methods for accessing the parsed data
   datetime          GetTimestamp() { return timestamp; }
   string            GetSymbol() { return symbol; }
   string            GetSide() { return side; }
   double            GetPrice() { return price; }
   double            GetQuantity() { return quantity; }
   string            GetComment() { return comment; }
   string            GetOrderID() { return orderID; }
  };


//+------------------------------------------------------------------+
