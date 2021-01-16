%
%  Dies ist eine Octave-Skript zur Darstellung von Daten die über die
%  serielle Schnittstelle empfangen werden (z.B. ein EKG-Signal).
%  Die Daten können mit einer Kaskade von digitalen Filtern gefiltert werden.
%
%  (c) Jens Bongartz, Januar 2021, RheinAhrCampus Remagen
%  Stand: 16.01.2021 
%
pkg load instrument-control;
clear all;
disp('Open SerialPort!')
#Windows - COM anpassen
#serial_01 = serialport("COM12",115200);
#MacOSX - Pfad anpassen!
serial_01 = serialport("/dev/cu.usbserial-1420",115200); 

configureTerminator(serial_01,"lf");
flush(serial_01);
adc_array = [];
x_index = 0;
cr_lf = [char(13) char(10)];      %% Zeichenkette CR/LF
inBuffer = [];                    %% Buffer serielle Schnittstelle

% Digitaler Filter:
% ===================================================================================
% HP01 = Hochpass-Filter 1 Hz 
% No50 = Notch-Filter 50Hz
% TP40 = Tiefpass-Filter 40 Hz
% ==============================
% Filterkoeffizienten
HP01_ko = [ 0.9780302754084559 -1.9560605508169118 0.9780302754084559 ...
           -1.9555778328194147 0.9565432688144089 ];
No50_ko = [ 0.5857841106784856 -1.3007020142696517e-16 0.5857841106784856 ...
           -1.3007020142696517e-16 0.17156822135697122 ];
TP40_ko = [ 0.20657128726265578 0.41314257452531156 0.20657128726265578 ...
           -0.36952595241514796 0.19581110146577102 ];
% Filterstufen
HP01_sp = [0 0 0 0 0 0];                    % Filter-Speicher
No50_sp = [0 0 0 0 0 0];                    % Filter-Speicher
TP40_sp = [0 0 0 0 0 0];                    % Filter-Speicher
% Checkbox-Variablen
global HP01_filtered = 0;
global No50_filtered = 0;
global TP40_filtered = 0;
% Filterimplementierung
function [adc,sp] = digitalerFilter(adc,sp,ko);
   sp(3) = sp(2); sp(2) = sp(1); sp(1) = adc; sp(6) = sp(5) ; sp(5) = sp(4);
   sp(4) = sp(1)*ko(1)+sp(2)*ko(2)+sp(3)*ko(3)-sp(5)*ko(4)-sp(6)*ko(5);
   adc   = sp(4);  
endfunction
% ======================================================================================
% Low-Level-Plotting
% ====================
fi_1 = figure(1);
clf
ax_1 = axes("box","on","xlim",[1 600]); %,"ylim",[-500 500]);
li_1 = line("color","blue");

% GUI-Elemente
% ============

% "HP 1Hz " Checkbox
% =====================================================================================
cb_HP01 = uicontrol(fi_1,"style","checkbox","string","HP 1 Hz", ...
                    "callback","cb_HP01_changed","position",[10,10,150,30]);

function cb_HP01_changed;
  global HP01_filtered;
  HP01_filtered = not(HP01_filtered);
endfunction

% "Notch 50Hz" Checkbox
cb_No50 = uicontrol(fi_1,"style","checkbox","string","Notch 50Hz", ...
                    "callback","cb_No50_changed","position",[150,10,150,30]);

function cb_No50_changed;
  global No50_filtered;
  No50_filtered = not(No50_filtered);
endfunction

% "TP 40Hz" Checkbox
cb_TP40 = uicontrol(fi_1,"style","checkbox","string","TP 40Hz", ...
                  "callback","cb_TP40_changed","position",[300,10,150,30]);

function cb_TP40_changed;
  global TP40_filtered;
  TP40_filtered = not(TP40_filtered);
endfunction
% Quit-Button
Quit_Button = uicontrol(fi_1,"style","pushbutton","string","Quit",...
                        "callback","Quit_Button_pressed","position",[450,10,100,30]);

function Quit_Button_pressed
  global quit_prg;
  quit_prg = 1;
endfunction
% ====================================================================================

global quit_prg;
quit_prg = 0;
drawnow();

% ============================

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
        tic
        inChar   = inBuffer(1:posCRLF-1);
        inChar   = inChar(~isspace(inChar));              %% Leerzeichen aus inChar entfernen
        inBuffer = inBuffer(posCRLF+2:end);        
        inNumbers = strsplit(inChar,{',','ADC:'});
        count = length(inNumbers);
        for i = 2:1:count                                 %% erste Element bei strsplit ist ´hier immer
           adc = str2num(inNumbers{i});
           if (HP01_filtered) 
                [adc,HP01_sp] = digitalerFilter(adc,HP01_sp,HP01_ko);
           endif                
           if (No50_filtered) 
                [adc,No50_sp] = digitalerFilter(adc,No50_sp,No50_ko);
           endif                
           if (TP40_filtered) 
                [adc,TP40_sp] = digitalerFilter(adc,TP40_sp,TP40_ko);
           endif                
           adc_array(end+1)=adc;
           x_index++;
        endfor
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
   endif     
   if (kbhit(1) == 'x')
     quit_prg = 1;
   endif
until(quit_prg);    %% Programmende wenn x-Taste gedrückt wird

clear serial_01;