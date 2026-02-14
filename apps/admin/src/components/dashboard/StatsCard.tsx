import { ReactNode, ComponentType, SVGProps, isValidElement, createElement } from 'react';
import { ArrowUpIcon, ArrowDownIcon } from '@heroicons/react/24/solid';

interface StatsCardProps {
  title: string;
  value: string | number;
  icon: ReactNode | ComponentType<SVGProps<SVGSVGElement>>;
  change?: number | {
    value: number;
    type: 'increase' | 'decrease';
  };
  trend?: 'up' | 'down';
  description?: string;
}

// Helper to check if something is a React component (function or forwardRef)
function isReactComponent(value: unknown): value is ComponentType<SVGProps<SVGSVGElement>> {
  if (typeof value === 'function') return true;
  // Check for forwardRef components which have $$typeof and render
  if (typeof value === 'object' && value !== null && '$$typeof' in value) {
    return true;
  }
  return false;
}

export function StatsCard({ title, value, icon, change, trend, description }: StatsCardProps) {
  // Determine the change value and type
  let changeValue: number | undefined;
  let changeType: 'increase' | 'decrease' | undefined;

  if (typeof change === 'number') {
    changeValue = Math.abs(change);
    changeType = trend === 'down' ? 'decrease' : (change >= 0 ? 'increase' : 'decrease');
  } else if (change) {
    changeValue = change.value;
    changeType = change.type;
  }

  // Render the icon - handle both ReactNode and Component types
  const renderIcon = () => {
    if (!icon) return null;

    // If it's already a valid React element (JSX), return as-is
    if (isValidElement(icon)) {
      return icon;
    }

    // Check if it's a component (function or forwardRef) that needs to be instantiated
    if (isReactComponent(icon)) {
      return createElement(icon, { className: 'h-6 w-6' });
    }

    return icon;
  };

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          <p className="mt-1 text-3xl font-semibold text-gray-900">
            {typeof value === 'number' ? value.toLocaleString() : value}
          </p>
        </div>
        <div className="rounded-lg bg-primary-50 p-3 text-primary-500">{renderIcon()}</div>
      </div>

      {(changeValue !== undefined || description) && (
        <div className="mt-4 flex items-center text-sm">
          {changeValue !== undefined && changeType && (
            <span
              className={`flex items-center ${
                changeType === 'increase' ? 'text-green-600' : 'text-red-600'
              }`}
            >
              {changeType === 'increase' ? (
                <ArrowUpIcon className="mr-1 h-4 w-4" />
              ) : (
                <ArrowDownIcon className="mr-1 h-4 w-4" />
              )}
              {changeValue}%
            </span>
          )}
          {description && (
            <span className="ml-2 text-gray-500">{description}</span>
          )}
        </div>
      )}
    </div>
  );
}
