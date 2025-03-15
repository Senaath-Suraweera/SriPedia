import os
import json
import datetime
import tempfile
import re
from django.core.management.base import BaseCommand
from authentication.models import SpecialDate
from django_auth_project.firebase import bucket
from authentication.deepseek_service import DeepseekService  # Import your deepseek service

class Command(BaseCommand):
    help = 'Import special dates from ALL_TEXTBOOK_DATA folder in Firebase Storage'

    def add_arguments(self, parser):
        parser.add_argument('--prefix', type=str, default='ALL_TEXTBOOK_DATA/', 
                           help='Firebase Storage prefix path (folder name)')
        parser.add_argument('--verbose', action='store_true', help='Show verbose output')
        parser.add_argument('--limit', type=int, default=None, help='Limit the number of PDFs to process')

    def handle(self, *args, **options):
        storage_prefix = options.get('prefix', 'ALL_TEXTBOOK_DATA/')
        verbose = options.get('verbose', False)
        limit = options.get('limit')
        
        self.stdout.write(f'Importing special dates from Firebase Storage PDFs: {storage_prefix}')
        
        count = 0
        skipped = 0
        errors = 0
        files_found = 0
        files_processed = 0
        
        # Initialize the deepseek service
        deepseek = DeepseekService()
        
        # List all blobs in the specified prefix
        blobs = list(bucket.list_blobs(prefix=storage_prefix))
        
        if not blobs:
            self.stdout.write(self.style.WARNING(f'No files found in Firebase Storage with prefix: {storage_prefix}'))
            return
            
        self.stdout.write(f'Found {len(blobs)} total files in Firebase Storage')
        
        # Process each PDF file found in Firebase Storage
        for blob in blobs:
            if blob.name.endswith('.pdf'):
                files_found += 1
                self.stdout.write(f'Processing PDF file: {blob.name}')
                
                # Apply limit if specified
                if limit and files_processed >= limit:
                    self.stdout.write(f'Reached processing limit of {limit} files')
                    break
                
                try:
                    # Download the file to a temporary location
                    with tempfile.NamedTemporaryFile(suffix='.pdf') as temp_file:
                        blob.download_to_filename(temp_file.name)
                        files_processed += 1
                        
                        # Extract text from PDF using deepseek_service
                        self.stdout.write(f'Extracting text from PDF using deepseek_service')
                        
                        prompt = """
                        Extract important historical dates and events from this textbook content. 
                        For each important date, provide the following:
                        1. Title of the event
                        2. Date in YYYY-MM-DD format (if only year is known, use YYYY-01-01)
                        3. A brief description of the event
                        
                        Format the output as a JSON array of objects, each with 'title', 'date', and 'description' fields.
                        Example:
                        [
                            {
                                "title": "Declaration of Independence",
                                "date": "1776-07-04",
                                "description": "The day when the United States declared independence from Great Britain."
                            },
                            ...
                        ]
                        """
                        
                        # Call deepseek with the PDF file
                        try:
                            response = deepseek.process_document(
                                file_path=temp_file.name,
                                prompt=prompt
                            )
                            
                            if verbose:
                                self.stdout.write(f'Deepseek response: {response}')
                            
                            # Extract JSON data from the response
                            # The response might contain explanatory text, so we need to extract just the JSON part
                            json_match = re.search(r'\[[\s\S]*\]', response)
                            if json_match:
                                json_str = json_match.group(0)
                                try:
                                    dates_data = json.loads(json_str)
                                    
                                    if verbose:
                                        self.stdout.write(f'Found {len(dates_data)} dates in response')
                                    
                                    # Process each date entry
                                    for date_entry in dates_data:
                                        title = date_entry.get('title', 'Untitled Event')
                                        description = date_entry.get('description', '')
                                        date_str = date_entry.get('date')
                                        source = blob.name
                                        
                                        if not date_str:
                                            if verbose:
                                                self.stdout.write(self.style.WARNING(f'No date string found in entry: {date_entry}'))
                                            continue
                                        
                                        try:
                                            # Parse date - expect YYYY-MM-DD format from deepseek
                                            parsed_date = None
                                            for date_format in ['%Y-%m-%d', '%Y-%m', '%Y']:
                                                try:
                                                    if date_format == '%Y' and len(date_str) == 4:
                                                        # For year-only entries, set to January 1st
                                                        parsed_date = datetime.datetime.strptime(date_str + "-01-01", "%Y-%m-%d").date()
                                                    elif date_format == '%Y-%m' and len(date_str) == 7:
                                                        # For year-month entries, set to 1st of the month
                                                        parsed_date = datetime.datetime.strptime(date_str + "-01", "%Y-%m-%d").date()
                                                    else:
                                                        parsed_date = datetime.datetime.strptime(date_str, date_format).date()
                                                    break
                                                except ValueError:
                                                    continue
                                            
                                            if not parsed_date:
                                                self.stdout.write(self.style.WARNING(
                                                    f'Could not parse date: {date_str} in file {blob.name}'
                                                ))
                                                continue
                                            
                                            # Check if this date already exists in the database
                                            existing_date = SpecialDate.objects.filter(
                                                title=title,
                                                date=parsed_date
                                            ).exists()
                                            
                                            if not existing_date:
                                                SpecialDate.objects.create(
                                                    title=title,
                                                    date=parsed_date,
                                                    description=description,
                                                    source=source
                                                )
                                                count += 1
                                                if verbose:
                                                    self.stdout.write(f'Created date: {parsed_date} - {title}')
                                            else:
                                                skipped += 1
                                                if verbose:
                                                    self.stdout.write(f'Skipped existing date: {parsed_date} - {title}')
                                        
                                        except Exception as e:
                                            self.stdout.write(self.style.WARNING(
                                                f'Error processing date entry: {e}'
                                            ))
                                            errors += 1
                                
                                except json.JSONDecodeError as e:
                                    self.stdout.write(self.style.ERROR(f'Error parsing JSON from deepseek response: {e}'))
                                    errors += 1
                            else:
                                self.stdout.write(self.style.WARNING(f'No JSON data found in deepseek response for {blob.name}'))
                                errors += 1
                        
                        except Exception as e:
                            self.stdout.write(self.style.ERROR(f'Error calling deepseek service: {e}'))
                            errors += 1
                
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f'Error downloading or processing file {blob.name}: {e}'))
                    errors += 1
        
        self.stdout.write(self.style.SUCCESS(
            f'Found {files_found} PDF files, processed {files_processed} files, '
            f'imported {count} special dates. Skipped {skipped} existing dates. '
            f'Encountered {errors} errors.'
        ))