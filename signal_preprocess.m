% Signal Preprossessing Module
% 
%     Author: Alexis Othonos
%     Date: 15.11.2017
%
%     Description: Find Voice and Un-Voice Regions by passing a 2-stage running
%     windowed average filter. The first stage will average the power of the signal 
%     while the second filter will smooth out the avg with a smaller window
% 

function [output1, output2] = signal_preprocess(input, fs, window_length)
    %Window size default value
    if nargin == 3
        window_size = window_length;
    elseif nargin == 2
            window_size = 0.01;
    end
             
    %Threshold: (default = 30%)
    percentage = 0.25;
    %Normalise signal
    signal = normalisation(input, fs);
    %Window period: 50msec
    %Start loop from beginning of signal, until the right edge 
    %of the window reaches the final signal value
    
    len = length(signal);

    %Voice-Unvoice vector: 
        %1 for voice
        %0 for unvoice
    %Find windowed average
    avg = median_filter(signal, fs, window_size);
    avg = median_filter(avg, fs, window_size);
    %Find max value
    avg_max = max(avg);
    %Pre-allocate voice array for speed
    voice = zeros(len,1);
    %Calculate threshold
    threshold = avg_max*percentage;
    %Set 0 or 1 if below or above threshold respectively. Additionally,
    %find the on-off states of the voice-unvoice pair. This is later used
    %to find the 'longest' voice within the current buffer(or file) and
    %analyze it:
        %on_off column 1 holds on transition while column 2 holds off
        %transition
    index = 1;
    for current = 1:len
        if avg(current) >= threshold
            voice(current) = 1;
        end
        %check only if current index is larger than 1
        if current > 1
            %if current is 1 and previous is 0 (on)
            if voice(current) > voice(previous)
                on_off(index,1) = current;
            %if current is 0 and previous is 1 (on)
            elseif voice(previous) > voice(current)
                on_off(index,2) = current;
                %increment index when 'off' is found
                index = index + 1;
            end
        %if current = 1, initialize previous to 1
        else
            previous = 1;
        end
        previous = current;
    end
    %Check if first and last element(1st column) is omplete
    if on_off(1,1) == 0
        %Reassign to first element
        on_off(1,1) = 1;
    end
    %Check if final element(2nd column) is complete
    if (index == length(on_off(:,1)))
        if on_off(index,2)== 0
            on_off(index, 2) = len;
        end
    end
    vector = diff(on_off, 1,2);
    [vector_max, vector_index] = max(vector);
    on_off = on_off(vector_index, :);
    %Create mask
    mask(1:on_off(1,1)-1) = 0;
    mask(on_off(1,1):on_off(1,2)) = 1;
    mask(on_off(1,2)+1:len) = 0;
    %Set output1
    output1 =  voice .* mask';
    %Set output2 
    avg = avg ./ max(avg);   
    output2 = avg;
    
    
    
    
