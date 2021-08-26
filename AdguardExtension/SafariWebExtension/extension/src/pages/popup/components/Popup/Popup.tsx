import React, { useContext, useEffect } from 'react';
import { observer } from 'mobx-react';

import { Icons } from '../../../common/ui/Icons';
import { Actions } from '../Actions';
import { Modals } from '../Modals';
import { popupStore } from '../../stores/PopupStore';
import { Support } from '../Support';
import { Loader } from '../Loader';
import { useFullscreen } from '../../hooks/useFullscreen';

// TODO CSS: can we import vars.pcss in popup.css?
import '../../../../vars.pcss';
import './popup.pcss';

export const Popup = observer(() => {
    const store = useContext(popupStore);

    useEffect(() => {
        store.getPopupData();
    }, []);

    useFullscreen((isFullscreen) => {
        store.setFullscreen(isFullscreen);
    });

    return (
        <div className="popup">
            <Icons />
            <Modals />
            <Actions />
            <Support />
            <Loader />
        </div>
    );
});