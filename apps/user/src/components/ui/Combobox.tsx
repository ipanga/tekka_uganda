'use client';

import { useState, Fragment } from 'react';
import { Combobox as HeadlessCombobox, Transition } from '@headlessui/react';
import { CheckIcon, ChevronUpDownIcon } from '@heroicons/react/24/outline';
import { cn } from '@/lib/utils';

export interface ComboboxOption {
  value: string;
  label: string;
}

export interface ComboboxProps {
  label?: string;
  options: ComboboxOption[];
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  error?: string;
  helperText?: string;
  showRequired?: boolean;
  disabled?: boolean;
  name?: string;
}

export function Combobox({
  label,
  options,
  value,
  onChange,
  placeholder = 'Select an option...',
  error,
  helperText,
  showRequired,
  disabled,
  name,
}: ComboboxProps) {
  const [query, setQuery] = useState('');

  const filteredOptions =
    query === ''
      ? options
      : options.filter((option) =>
          option.label.toLowerCase().includes(query.toLowerCase())
        );

  const selectedOption = options.find((opt) => opt.value === value);

  return (
    <div className="w-full">
      {label && (
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          {label}
          {showRequired && <span className="text-red-500 ml-1">*</span>}
        </label>
      )}
      <HeadlessCombobox
        value={value}
        onChange={(newValue: string | null) => {
          if (newValue !== null) {
            onChange(newValue);
          }
        }}
        disabled={disabled}
        name={name}
      >
        <div className="relative">
          <div className="relative w-full">
            <HeadlessCombobox.Input
              className={cn(
                'block w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-4 py-2.5',
                'text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500',
                'focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 focus:outline-none',
                'disabled:bg-gray-50 disabled:text-gray-500 disabled:cursor-not-allowed',
                'transition-colors duration-200',
                'pr-10',
                error && 'border-red-500 focus:border-red-500 focus:ring-red-500/20'
              )}
              displayValue={() => selectedOption?.label || ''}
              onChange={(event) => setQuery(event.target.value)}
              placeholder={placeholder}
            />
            <HeadlessCombobox.Button className="absolute inset-y-0 right-0 flex items-center pr-3">
              <ChevronUpDownIcon
                className="h-5 w-5 text-gray-400 dark:text-gray-500"
                aria-hidden="true"
              />
            </HeadlessCombobox.Button>
          </div>
          <Transition
            as={Fragment}
            leave="transition ease-in duration-100"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
            afterLeave={() => setQuery('')}
          >
            <HeadlessCombobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg bg-white dark:bg-gray-800 py-1 text-base shadow-lg ring-1 ring-black/5 dark:ring-white/10 focus:outline-none sm:text-sm">
              {filteredOptions.length === 0 && query !== '' ? (
                <div className="relative cursor-default select-none px-4 py-2 text-gray-500 dark:text-gray-400">
                  No results found.
                </div>
              ) : (
                filteredOptions.map((option) => (
                  <HeadlessCombobox.Option
                    key={option.value}
                    className={({ active }) =>
                      cn(
                        'relative cursor-pointer select-none py-2 pl-10 pr-4',
                        active ? 'bg-primary-50 dark:bg-primary-900 text-primary-900 dark:text-primary-100' : 'text-gray-900 dark:text-gray-100'
                      )
                    }
                    value={option.value}
                  >
                    {({ selected, active }) => (
                      <>
                        <span
                          className={cn(
                            'block truncate',
                            selected ? 'font-medium' : 'font-normal'
                          )}
                        >
                          {option.label}
                        </span>
                        {selected && (
                          <span
                            className={cn(
                              'absolute inset-y-0 left-0 flex items-center pl-3',
                              active ? 'text-primary-500 dark:text-primary-300' : 'text-primary-500 dark:text-primary-300'
                            )}
                          >
                            <CheckIcon className="h-5 w-5" aria-hidden="true" />
                          </span>
                        )}
                      </>
                    )}
                  </HeadlessCombobox.Option>
                ))
              )}
            </HeadlessCombobox.Options>
          </Transition>
        </div>
      </HeadlessCombobox>
      {error && <p className="mt-1 text-sm text-red-500">{error}</p>}
      {helperText && !error && (
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{helperText}</p>
      )}
    </div>
  );
}
