pkg load instrument-control;
clear all;
disp('Open SerialPort!')
#Windows - COM anpassen
serial_01 = serialport("COM12",115200);
#MacOSX - Pfad anpassen!
#serial_01 = serialport("/dev/cu.usbserial-1420",115200); 
configureTerminator(serial_01,"lf");
flush(serial_01);
adc_array = [];
x_index = 0;
cr_lf = [char(13) char(10)];      %% Zeichenkette CR/LF
inBuffer = [];                    %% Buffer serielle Schnittstelle
global quit_prg;
quit_prg = 0;

% Low-Level-Plotting vorbereiten
% ==============================
fi_1 = figure(1);
clf
ax_1 = axes("box","on","xlim",[1 600],"ylim",[0 1100]);
li_1 = line("color","blue");

bt1 = uicontrol(fi_1,"style","pushbutton","string","Quit",...
                "callback","bt1_pressed","position",[250,10,100,30]);

function bt1_pressed
  global quit_prg;
  quit_prg = 1;
endfunction

drawnow();

disp('Wait for data!')
do
until (serial_01.numbytesavailable > 0);

do
   bytesavailable = serial_01.numbytesavailable;
   
   if (bytesavailable > 0)
     %% Zeilenende (println) ist ASCII Kombination 13 10
     %% char(13) = CR char(10) = LF
     inSerialPort = char(read(serial_01,bytesavailable)); %% Daten werden vom SerialPort gelesen
     inBuffer     = [inBuffer inSerialPort];              %% und an den inBuffer angehängt
     posCRLF      = rindex(inBuffer, cr_lf);              %% Test auf CR/LF im inBuffer 
     if (posCRLF > 0)          
        inChar   = inBuffer(1:posCRLF-1);
        inChar   = inChar(~isspace(inChar));              %% Leerzeichen aus inChar entfernen
        inBuffer = inBuffer(posCRLF+2:end);        
        inNumbers = strsplit(inChar,{',','ADC:'});
        count = length(inNumbers);
        for i = 2:1:count                                 %% erste Element bei strsplit ist ´hier immer
           adc = str2num(inNumbers{i});
           adc_array(end+1)=adc;
           x_index++;
        endfor
     endif     
     tic
     % Low-Level-Plotting
     % ==================
     if (x_index > 600)
       x_axis = x_index-600:x_index;
       adc_plot = adc_array(x_index-600:x_index);
       axis([x_index-600 x_index]);
     else
       x_axis = 1:x_index;
       adc_plot = adc_array;
     endif
     set(li_1,"xdata",x_axis,"ydata",adc_plot);
     drawnow();
     toc
   endif
   
   if (kbhit(1) == 'x')
     quit_prg = 1;
   endif
   
until(quit_prg);    %% Programmende wenn x-Taste gedrückt wird

clear serial_01;

