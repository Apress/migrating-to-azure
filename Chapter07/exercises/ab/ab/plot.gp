# Output to a jpeg file
set terminal png size 1280,720

# Set the aspect ratio of the graph
set size 1, 1

# The file to write to
set output @ARG2

# The graph title
set title @ARG1

# Where to place the legend/key
set key left top

# Draw gridlines oriented on the y axis
set grid y

# Specify that the x-series data is time data
set xdata time

# Specify the *input* format of the time data
set timefmt "%s"

# Specify the *output* format for the x-axis tick labels
set format x "%S"

# Label the x-axis
set xlabel 'seconds'

# Label the y-axis
set ylabel "response time (ms)"

# Tell gnuplot to use tabs as the delimiter instead of spaces (default)
set datafile separator '\t'

# Plot the data
plot @ARG3 every ::2 using 2:5 title 'response time' with points