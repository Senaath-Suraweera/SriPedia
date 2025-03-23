import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from io import BytesIO
import base64

class DataVisualization:
    """
    Class for generating data visualizations for SriPedia
    """
    
    def __init__(self, theme='light'):
        """
        Initialize visualization settings
        
        Args:
            theme (str): 'light' or 'dark' theme for plots
        """
        self.theme = theme
        self._set_style()
        
    def _set_style(self):
        """Set the visual style based on theme"""
        if self.theme == 'dark':
            plt.style.use('dark_background')
            self.colors = ['#ff9999', '#66b3ff', '#99ff99', '#ffcc99', '#c2c2f0']
            self.text_color = 'white'
        else:
            plt.style.use('seaborn-v0_8-whitegrid')
            self.colors = ['#ff6666', '#3385ff', '#66cc66', '#ff9933', '#9494b8']
            self.text_color = 'black'
    
    def create_pie_chart(self, data, labels, title='', figsize=(8, 6), dpi=100):
        """
        Create a pie chart
        
        Args:
            data (list): List of values
            labels (list): List of labels
            title (str): Chart title
            figsize (tuple): Figure size (width, height) in inches
            dpi (int): DPI for the output figure
            
        Returns:
            str: Base64 encoded PNG image
        """
        plt.figure(figsize=figsize, dpi=dpi)
        plt.pie(data, labels=labels, autopct='%1.1f%%', startangle=90, colors=self.colors)
        plt.title(title, color=self.text_color, fontsize=14)
        plt.tight_layout()
        
        # Convert plot to base64 string
        buffer = BytesIO()
        plt.savefig(buffer, format='png')
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()
        
        return base64.b64encode(image_png).decode('utf-8')
    
    def create_bar_chart(self, x_data, y_data, title='', xlabel='', ylabel='', figsize=(10, 6), dpi=100, horizontal=False):
        """
        Create a bar chart
        
        Args:
            x_data (list): X-axis categories
            y_data (list): Y-axis values
            title (str): Chart title
            xlabel (str): X-axis label
            ylabel (str): Y-axis label
            figsize (tuple): Figure size (width, height) in inches
            dpi (int): DPI for the output figure
            horizontal (bool): If True, create a horizontal bar chart
            
        Returns:
            str: Base64 encoded PNG image
        """
        plt.figure(figsize=figsize, dpi=dpi)
        
        if horizontal:
            bars = plt.barh(x_data, y_data, color=self.colors[0])
            plt.ylabel(xlabel, color=self.text_color)
            plt.xlabel(ylabel, color=self.text_color)
        else:
            bars = plt.bar(x_data, y_data, color=self.colors[0])
            plt.xlabel(xlabel, color=self.text_color)
            plt.ylabel(ylabel, color=self.text_color)
        
        # Add value labels on bars
        for bar in bars:
            if horizontal:
                height = bar.get_width()
                plt.text(height + max(y_data) * 0.01, bar.get_y() + bar.get_height()/2, 
                        f'{height:.1f}', ha='left', va='center', color=self.text_color)
            else:
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2, height + max(y_data) * 0.01, 
                        f'{height:.1f}', ha='center', va='bottom', color=self.text_color)
        
        plt.title(title, color=self.text_color, fontsize=14)
        plt.xticks(color=self.text_color)
        plt.yticks(color=self.text_color)
        plt.tight_layout()
        
        # Convert plot to base64 string
        buffer = BytesIO()
        plt.savefig(buffer, format='png')
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()
        
        return base64.b64encode(image_png).decode('utf-8')
    
    def create_line_chart(self, x_data, y_data, title='', xlabel='', ylabel='', figsize=(10, 6), dpi=100, area=False):
        """
        Create a line chart
        
        Args:
            x_data (list): X-axis values
            y_data (list): Y-axis values
            title (str): Chart title
            xlabel (str): X-axis label
            ylabel (str): Y-axis label
            figsize (tuple): Figure size (width, height) in inches
            dpi (int): DPI for the output figure
            area (bool): If True, fill the area under the line
            
        Returns:
            str: Base64 encoded PNG image
        """
        plt.figure(figsize=figsize, dpi=dpi)
        
        if area:
            plt.fill_between(x_data, y_data, color=self.colors[0], alpha=0.3)
            
        plt.plot(x_data, y_data, color=self.colors[0], marker='o', linewidth=2)
        
        plt.title(title, color=self.text_color, fontsize=14)
        plt.xlabel(xlabel, color=self.text_color)
        plt.ylabel(ylabel, color=self.text_color)
        plt.xticks(color=self.text_color)
        plt.yticks(color=self.text_color)
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        # Convert plot to base64 string
        buffer = BytesIO()
        plt.savefig(buffer, format='png')
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()
        
        return base64.b64encode(image_png).decode('utf-8')
    
    def create_heatmap(self, data, row_labels=None, col_labels=None, title='', figsize=(10, 8), dpi=100):
        """
        Create a heatmap
        
        Args:
            data (list or ndarray): 2D data for heatmap
            row_labels (list): Labels for rows
            col_labels (list): Labels for columns
            title (str): Chart title
            figsize (tuple): Figure size (width, height) in inches
            dpi (int): DPI for the output figure
            
        Returns:
            str: Base64 encoded PNG image
        """
        plt.figure(figsize=figsize, dpi=dpi)
        
        # Convert data to numpy array if it's not already
        if isinstance(data, list):
            data = np.array(data)
        
        ax = sns.heatmap(data, annot=True, cmap='YlGnBu', linewidths=0.5, 
                         xticklabels=col_labels, yticklabels=row_labels)
        
        plt.title(title, color=self.text_color, fontsize=14)
        plt.xticks(color=self.text_color, rotation=45)
        plt.yticks(color=self.text_color, rotation=0)
        plt.tight_layout()
        
        # Convert plot to base64 string
        buffer = BytesIO()
        plt.savefig(buffer, format='png')
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()
        
        return base64.b64encode(image_png).decode('utf-8')
    
    def create_scatter_plot(self, x_data, y_data, title='', xlabel='', ylabel='', 
                           figsize=(10, 6), dpi=100, add_trend=False):
        """
        Create a scatter plot
        
        Args:
            x_data (list): X-axis values
            y_data (list): Y-axis values
            title (str): Chart title
            xlabel (str): X-axis label
            ylabel (str): Y-axis label
            figsize (tuple): Figure size (width, height) in inches
            dpi (int): DPI for the output figure
            add_trend (bool): If True, add a trend line
            
        Returns:
            str: Base64 encoded PNG image
        """
        plt.figure(figsize=figsize, dpi=dpi)
        
        plt.scatter(x_data, y_data, color=self.colors[0], alpha=0.7)
        
        if add_trend and len(x_data) > 1:
            # Add trend line
            z = np.polyfit(x_data, y_data, 1)
            p = np.poly1d(z)
            plt.plot(x_data, p(x_data), color=self.colors[1], linestyle='--')
        
        plt.title(title, color=self.text_color, fontsize=14)
        plt.xlabel(xlabel, color=self.text_color)
        plt.ylabel(ylabel, color=self.text_color)
        plt.xticks(color=self.text_color)
        plt.yticks(color=self.text_color)
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        # Convert plot to base64 string
        buffer = BytesIO()
        plt.savefig(buffer, format='png')
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()
        
        return base64.b64encode(image_png).decode('utf-8')
    
    def create_dashboard(self, charts, title='SriPedia Analytics Dashboard', figsize=(12, 10), dpi=100):
        """
        Create a dashboard with multiple charts
        
        Args:
            charts (list): List of (chart_type, chart_data) tuples
                chart_type: 'pie', 'bar', 'line', 'scatter', 'heatmap'
                chart_data: dict with data and parameters for the specific chart type
            title (str): Dashboard title
            figsize (tuple): Figure size (width, height) in inches
            dpi (int): DPI for the output figure
            
        Returns:
            str: Base64 encoded PNG image
        """
        num_charts = len(charts)
        if num_charts == 0:
            return None
        
        # Calculate layout
        if num_charts == 1:
            rows, cols = 1, 1
        elif num_charts == 2:
            rows, cols = 1, 2
        elif num_charts <= 4:
            rows, cols = 2, 2
        elif num_charts <= 6:
            rows, cols = 2, 3
        else:
            rows = (num_charts + 2) // 3
            cols = 3
        
        fig, axes = plt.subplots(rows, cols, figsize=figsize, dpi=dpi)
        fig.suptitle(title, fontsize=16, color=self.text_color)
        
        # Flatten axes array for easier indexing
        if rows > 1 or cols > 1:
            axes = axes.flatten()
        else:
            axes = [axes]
        
        for i, (chart_type, chart_data) in enumerate(charts):
            if i >= len(axes):
                break
                
            ax = axes[i]
            plt.sca(ax)
            
            if chart_type == 'pie':
                ax.pie(chart_data['data'], labels=chart_data.get('labels'), 
                       autopct='%1.1f%%', startangle=90, colors=self.colors)
                ax.set_title(chart_data.get('title', ''), color=self.text_color)
                
            elif chart_type == 'bar':
                ax.bar(chart_data['x_data'], chart_data['y_data'], color=self.colors[0])
                ax.set_xlabel(chart_data.get('xlabel', ''), color=self.text_color)
                ax.set_ylabel(chart_data.get('ylabel', ''), color=self.text_color)
                ax.set_title(chart_data.get('title', ''), color=self.text_color)
                
            elif chart_type == 'line':
                ax.plot(chart_data['x_data'], chart_data['y_data'], 
                        color=self.colors[0], marker='o', linewidth=2)
                ax.set_xlabel(chart_data.get('xlabel', ''), color=self.text_color)
                ax.set_ylabel(chart_data.get('ylabel', ''), color=self.text_color)
                ax.set_title(chart_data.get('title', ''), color=self.text_color)
                ax.grid(True, linestyle='--', alpha=0.7)
                
            elif chart_type == 'scatter':
                ax.scatter(chart_data['x_data'], chart_data['y_data'], color=self.colors[0], alpha=0.7)
                ax.set_xlabel(chart_data.get('xlabel', ''), color=self.text_color)
                ax.set_ylabel(chart_data.get('ylabel', ''), color=self.text_color)
                ax.set_title(chart_data.get('title', ''), color=self.text_color)
                ax.grid(True, linestyle='--', alpha=0.7)
                
            elif chart_type == 'heatmap':
                data = chart_data['data']
                if isinstance(data, list):
                    data = np.array(data)
                sns.heatmap(data, annot=True, cmap='YlGnBu', linewidths=0.5, 
                           xticklabels=chart_data.get('col_labels'), 
                           yticklabels=chart_data.get('row_labels'), ax=ax)
                ax.set_title(chart_data.get('title', ''), color=self.text_color)
            
            # Set tick colors
            ax.tick_params(colors=self.text_color)
        
        # Hide unused subplots
        for i in range(num_charts, len(axes)):
            axes[i].axis('off')
            
        plt.tight_layout(rect=[0, 0, 1, 0.96])  # Adjust for suptitle
        
        # Convert plot to base64 string
        buffer = BytesIO()
        plt.savefig(buffer, format='png')
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()
        
        return base64.b64encode(image_png).decode('utf-8')

# Example usage
if __name__ == "__main__":
    # Create visualizer
    visualizer = DataVisualization(theme='light')
    
    # Sample data
    categories = ['Category A', 'Category B', 'Category C', 'Category D']
    values = [30, 25, 15, 30]
    
    # Create pie chart
    pie_chart = visualizer.create_pie_chart(
        data=values,
        labels=categories,
        title='Sample Distribution'
    )
    
    # Print base64 encoded image
    print(f"Generated pie chart with {len(pie_chart)} chars")